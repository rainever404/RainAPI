"""Exercise isolated, real database upgrades using locally built Docker images.

No production access. Only containers, network and volumes created by this run
are removed. Test credentials are random and never written to the report.
"""

import argparse
import hashlib
import http.cookiejar
import json
import pathlib
import secrets
import sqlite3
import subprocess
import time
import urllib.error
import urllib.request


def digest(value):
    return hashlib.sha256(value.encode()).hexdigest()


class UpgradeCheck:
    def __init__(self, args):
        self.args = args
        self.prefix = "rainapi-verify-" + secrets.token_hex(4)
        self.password = secrets.token_hex(20)
        self.containers = []
        self.volumes = []
        self.network_created = False
        self.root = pathlib.Path(args.output).resolve().parent / self.prefix
        self.root.mkdir(parents=True)
        self.report = {"candidate": args.image, "cases": [], "status": "running"}

    def docker(self, *args, stdin=None, timeout=180, check=True):
        result = subprocess.run(
            ["docker", *args], input=stdin, capture_output=True,
            encoding="utf-8", errors="replace", timeout=timeout,
        )
        if check and result.returncode:
            error = (result.stderr + result.stdout).replace(self.password, "[test-password]")
            raise RuntimeError(f"docker {args[0]} failed: {error[-5000:]}")
        return (result.stdout + (result.stderr if args[0] == "logs" else "")).strip()

    def start(self, name, image, *args, network=None):
        self.containers.append(name)
        return self.docker("run", "-d", "--name", name, "--network", network or self.prefix,
                           "--label", f"rainapi.verify={self.prefix}", *args, image)

    def sql(self, engine, database, statement):
        if engine == "sqlite":
            with sqlite3.connect(self.root / f"{database}.db") as connection:
                cursor = connection.execute(statement)
                rows = cursor.fetchall() if cursor.description else []
            return "\n".join("\t".join("" if v is None else str(v) for v in row) for row in rows)
        if engine == "postgres":
            return self.docker("exec", "-i", self.prefix + "-pg", "psql", "-U", "root",
                               "-d", database, "-A", "-t", "-F", "\t", "-v", "ON_ERROR_STOP=1",
                               stdin=statement)
        return self.docker("exec", "-i", "-e", "MYSQL_PWD=" + self.password,
                           self.prefix + "-mysql", "mysql", "-uroot", "--batch",
                           "--raw", "--skip-column-names", database, stdin=statement)

    def create_database(self, engine, database):
        if engine != "sqlite":
            self.sql(engine, "postgres" if engine == "postgres" else "mysql",
                     "CREATE DATABASE " + database +
                     (" CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci" if engine == "mysql" else ""))

    def dsn(self, engine, database, loopback=False):
        if engine == "sqlite":
            return "local"
        host = "127.0.0.1" if loopback else self.prefix + "-pg"
        if engine == "postgres":
            return f"postgres://root:{self.password}@{host}:5432/{database}?sslmode=disable"
        return f"root:{self.password}@tcp({host}:3306)/{database}?charset=utf8mb4&parseTime=True&loc=Local"

    def wait_database(self, engine):
        deadline = time.monotonic() + 120
        while time.monotonic() < deadline:
            try:
                if self.sql(engine, "postgres" if engine == "postgres" else "mysql", "SELECT 1") == "1":
                    return
            except RuntimeError:
                time.sleep(2)
        raise RuntimeError(engine + " failed to become ready")

    def api(self, base, path, data=None, opener=None):
        request = urllib.request.Request(
            base + path, None if data is None else json.dumps(data).encode(),
            {"Content-Type": "application/json"},
        )
        with (opener or urllib.request.build_opener(urllib.request.ProxyHandler({}))).open(request, timeout=8) as response:
            payload = json.load(response)
        if not payload.get("success"):
            raise RuntimeError(path + " failed: " + str(payload.get("message")))
        return payload

    def app(self, image, engine, database, suffix):
        name = self.prefix + "-" + suffix
        env = ["-e", "SQL_DSN=" + self.dsn(engine, database),
               "-e", "REDIS_CONN_STRING=redis://" + self.prefix + "-redis:6379/0",
               "-e", "SESSION_SECRET=" + self.password,
               "-e", "GLOBAL_API_RATE_LIMIT_ENABLE=false", "-e", "TZ=UTC"]
        if engine == "sqlite":
            env += ["-e", f"SQLITE_PATH=/verify/{database}.db",
                    "-v", str(self.root) + ":/verify"]
        else:
            env += ["-e", "LOG_SQL_DSN=" + self.dsn(engine, database + "_log")]
        self.start(name, image, *env, "-p", "127.0.0.1::3000")
        try:
            port = self.docker("port", name, "3000/tcp").rsplit(":", 1)[1]
        except (RuntimeError, IndexError):
            raise RuntimeError("App exited before binding its port: " + self.docker("logs", "--tail", "25", name, check=False).replace(self.password, "[test-password]"))
        base = "http://127.0.0.1:" + port
        deadline = time.monotonic() + 90
        while time.monotonic() < deadline:
            try:
                self.api(base, "/api/status")
                return name, base
            except (urllib.error.URLError, TimeoutError, ConnectionError, RuntimeError):
                if self.docker("inspect", name, "--format", "{{.State.Running}}") != "true":
                    break
                time.sleep(1)
        logs = self.docker("logs", "--tail", "35", name, check=False)
        raise RuntimeError("App startup failed: " + logs.replace(self.password, "[test-password]"))

    def stop(self, name):
        self.docker("stop", "-t", "10", name)

    def seed(self, engine, database):
        quote = '`' if engine == "mysql" else '"'
        q = lambda name: quote + name + quote
        statements = [
            "UPDATE users SET quota=123456789,used_quota=2345,request_count=8 WHERE id=1",
            "INSERT INTO users (id,username,password,role,status,aff_code) VALUES (901,'passkey-only','fixture-unusable-password',1,1,'fixture-aff')",
            f"INSERT INTO tokens (id,user_id,{q('key')},status,name,expired_time,remain_quota,used_quota,{q('group')}) VALUES (901,1,'fixture-token',1,'preserve-token',-1,456789,123,'Preview')",
            f"INSERT INTO channels (id,type,{q('key')},status,name,models,{q('group')}) VALUES (901,57,'fixture-credential',2,'preserve-channel','gpt-6-astra','All Model,Preview')",
            "INSERT INTO passkey_credentials (id,user_id,credential_id,public_key,sign_count) VALUES (901,901,'Zml4dHVyZQ==','Zml4dHVyZQ==',7)",
            "INSERT INTO prefill_groups (id,name,type,items) VALUES (901,'preserve-group','model','[\"gpt-6-sol\",\"gpt-6-astra\"]')",
        ]
        source = "// fixture\n" + "x" * 32000
        statements.append(
            f"INSERT INTO task_plugins (id,{q('key')},api_version,version,source,source_hash,enabled,active,created_at) VALUES "
            f"(901,'preserve-plugin',1,'1.0.0','{source}','{digest(source)}',false,false,1)"
        )
        prices = json.loads((pathlib.Path(__file__).parent / "openai-standard-pricing.json").read_text(encoding="utf-8"))
        # Load the reviewed production expressions, not a fresh builtin default.
        options = {"billing_setting.billing_expr": prices["expressions"],
                   "billing_setting.billing_mode": {model: "tiered_expr" for model in prices["expressions"]}}
        for key, value in options.items():
            escaped_key = key.replace("'", "''")
            escaped_value = json.dumps(value, ensure_ascii=False, separators=(",", ":")).replace("'", "''")
            if engine == "mysql":
                escaped_value = escaped_value.replace("\\", "\\\\")
            statements.extend([
                f"DELETE FROM options WHERE {q('key')}='{escaped_key}'",
                f"INSERT INTO options ({q('key')},value) VALUES ('{escaped_key}','{escaped_value}')",
            ])
        for statement in statements:
            self.sql(engine, database, statement)
        logdb = database if engine == "sqlite" else database + "_log"
        self.sql(engine, logdb, "INSERT INTO logs (id,user_id,created_at,type,content,quota,model_name) VALUES (901,1,1,2,'preserve-log',2345,'gpt-6-sol')")

    def snapshot(self, engine, database):
        q = lambda value: ('`' + value + '`') if engine == "mysql" else ('"' + value + '"')
        queries = {
            "users": "SELECT id,username,password,role,status,quota,used_quota,request_count FROM users ORDER BY id",
            "tokens": f"SELECT id,user_id,{q('key')},status,name,expired_time,remain_quota,used_quota,{q('group')} FROM tokens ORDER BY id",
            "channels": f"SELECT id,type,{q('key')},status,name,models,{q('group')} FROM channels ORDER BY id",
            "passkeys": "SELECT id,user_id,credential_id,public_key,sign_count FROM passkey_credentials ORDER BY id",
            "prefill": "SELECT id,name,type,items FROM prefill_groups ORDER BY id",
            "plugins": f"SELECT id,{q('key')},api_version,version,source,source_hash,enabled,active FROM task_plugins WHERE id=901",
            "options": f"SELECT {q('key')},value FROM options ORDER BY {q('key')}",
        }
        result = {key: digest(self.sql(engine, database, sql)) for key, sql in queries.items()}
        logdb = database if engine == "sqlite" else database + "_log"
        result["logs"] = digest(self.sql(engine, logdb, "SELECT id,user_id,created_at,type,content,quota,model_name FROM logs WHERE id=901"))
        return result

    def schema(self, engine, database):
        if engine == "sqlite":
            query = "SELECT type,name,tbl_name,sql FROM sqlite_master WHERE sql IS NOT NULL ORDER BY type,name"
        elif engine == "postgres":
            query = "SELECT table_name,column_name,data_type,coalesce(character_maximum_length::text,''),is_nullable,coalesce(column_default,'') FROM information_schema.columns WHERE table_schema='public' ORDER BY table_name,ordinal_position"
        else:
            query = "SELECT table_name,column_name,column_type,is_nullable,coalesce(column_default,''),column_key,extra FROM information_schema.columns WHERE table_schema=database() ORDER BY table_name,ordinal_position"
        value = self.sql(engine, database, query)
        if engine == "postgres":
            value += self.sql(engine, database, "SELECT tablename,indexname,indexdef FROM pg_indexes WHERE schemaname='public' ORDER BY tablename,indexname")
        elif engine == "mysql":
            value += self.sql(engine, database, "SELECT table_name,index_name,non_unique,seq_in_index,column_name FROM information_schema.statistics WHERE table_schema=database() ORDER BY table_name,index_name,seq_in_index")
        return digest(value)

    def case(self, engine, baseline, index):
        database = f"verify_{engine}_{index}"
        self.create_database(engine, database)
        if engine != "sqlite":
            self.create_database(engine, database + "_log")
        name, base = self.app(baseline or self.args.image, engine, database, f"{engine}-{index}-base")
        self.api(base, "/api/setup", {"username": "verify", "password": self.password,
                                     "confirmPassword": self.password, "SelfUseModeEnabled": True})
        self.stop(name)
        self.seed(engine, database)
        before = self.snapshot(engine, database)
        schemas = []
        for start in range(2):
            name, base = self.app(self.args.image, engine, database, f"{engine}-{index}-{start}")
            after = self.snapshot(engine, database)
            changed = [key for key in before if before[key] != after[key]]
            if changed:
                raise RuntimeError(f"{engine}/{baseline}: changed fixture data: {changed}")
            schemas.append([self.schema(engine, database), self.schema(engine, database + "_log") if engine != "sqlite" else None])
            opener = urllib.request.build_opener(urllib.request.ProxyHandler({}), urllib.request.HTTPCookieProcessor(http.cookiejar.CookieJar()))
            login = self.api(base, "/api/user/login", {"username": "verify", "password": self.password}, opener)
            opener.addheaders = [("Authorization", "Bearer " + login["data"]["access_token"])]
            self.api(base, "/api/user/self", opener=opener)
            self.stop(name)
        if schemas[0] != schemas[1]:
            raise RuntimeError(f"{engine}/{baseline}: schema changed on repeated startup")
        source = "x" * 200000
        self.sql(engine, database, "UPDATE task_plugins SET source='" + source + "' WHERE id=901")
        if self.sql(engine, database, "SELECT length(source) FROM task_plugins WHERE id=901") != "200000":
            raise RuntimeError("Large plugin source was truncated")
        result = {"engine": engine, "baseline": baseline or "fresh", "status": "passed",
                  "preserved": list(before), "startup_count": 2, "schema_stable": True,
                  "login_and_session": True, "large_plugin_source_bytes": 200000,
                  "separate_log_database": engine != "sqlite"}
        self.report["cases"].append(result)
        print(json.dumps(result), flush=True)

    def go_tests(self):
        for engine in ["postgres", "mysql"]:
            self.create_database(engine, "unit_tests")
        name = self.prefix + "-go"
        self.containers.append(name)
        result = subprocess.run([
            "docker", "run", "--name", name, "--network", "container:" + self.prefix + "-pg",
            "--label", f"rainapi.verify={self.prefix}", "-e", "TEST_POSTGRES_DSN=" + self.dsn("postgres", "unit_tests", True),
            "-e", "TEST_MYSQL_DSN=" + self.dsn("mysql", "unit_tests", True),
            "-e", "GOPROXY=https://goproxy.cn,direct", "-e", "HTTPS_PROXY=http://host.docker.internal:7897",
            "-v", "rainapi-go-build-cache:/root/.cache/go-build", self.args.go_image,
            "sh", "-c", "go vet ./... && go build ./... && go test -p 1 -v ./... && cd relaykit && GOWORK=off go vet ./... && GOWORK=off go build ./... && GOWORK=off go test ./...",
        ], capture_output=True, encoding="utf-8", errors="replace", timeout=1800)
        log = (result.stdout + result.stderr).replace(self.password, "[test-password]")
        (self.root / "go-checks.log").write_text(log, encoding="utf-8")
        if result.returncode:
            raise RuntimeError("Go checks failed; see " + str(self.root / "go-checks.log") + "\n" + log[-5000:])
        self.report["go_checks"] = {"status": "passed", "image": self.args.go_image,
                                     "mysql_and_postgres_configured": True, "log": str(self.root / "go-checks.log")}
        print("Go vet/build/tests passed for root and standalone relaykit", flush=True)

    def run(self):
        try:
            self.report["image_id"] = self.docker("image", "inspect", self.args.image, "--format", "{{.Id}}")
            self.docker("network", "create", "--label", f"rainapi.verify={self.prefix}", self.prefix)
            self.network_created = True
            for kind, image, mount, env in [
                ("pg", "postgres:18.1-alpine", "/var/lib/postgresql", ["-e", "POSTGRES_USER=root", "-e", "POSTGRES_PASSWORD=" + self.password]),
                ("mysql", "mysql:5.7.44", "/var/lib/mysql", ["-e", "MYSQL_ROOT_PASSWORD=" + self.password, "-e", "MYSQL_ROOT_HOST=%"]),
            ]:
                volume = self.prefix + "-" + kind
                self.docker("volume", "create", "--label", f"rainapi.verify={self.prefix}", volume)
                self.volumes.append(volume)
                self.start(volume, image, "-v", volume + ":" + mount, *env,
                           network="container:" + self.prefix + "-pg" if kind == "mysql" else None)
            self.start(self.prefix + "-redis", "redis:7-alpine")
            self.wait_database("postgres")
            self.wait_database("mysql")
            self.report["databases"] = {
                "postgres": self.sql("postgres", "postgres", "SELECT version()"),
                "mysql": self.sql("mysql", "mysql", "SELECT version()"),
                "sqlite": sqlite3.sqlite_version,
            }
            for engine in ["sqlite", "mysql", "postgres"]:
                for index, baseline in enumerate([None, *self.args.baseline]):
                    self.case(engine, baseline, index)
            if self.args.go_image:
                self.go_tests()
            self.report["status"] = "passed"
        except Exception as error:
            self.report["status"] = "failed"
            self.report["error"] = str(error).replace(self.password, "[test-password]")
            raise
        finally:
            for name in reversed(self.containers):
                self.docker("rm", "-f", name, check=False)
            for volume in self.volumes:
                self.docker("volume", "rm", volume, check=False)
            if self.network_created:
                self.docker("network", "rm", self.prefix, check=False)
            pathlib.Path(self.args.output).write_text(json.dumps(self.report, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")


if __name__ == "__main__":
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--image", required=True, help="Locally built candidate image")
    parser.add_argument("--baseline", action="append", default=[], help="Old release image; repeat for production and latest official release")
    parser.add_argument("--go-image", help="Optional builder2 image for root/relaykit vet, build and tests against real databases")
    parser.add_argument("--output", default=".local-tests/upgrade-report.json")
    UpgradeCheck(parser.parse_args()).run()
