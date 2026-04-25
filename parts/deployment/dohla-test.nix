{
  lib,
  config,
  pkgs,
  inputs,
  ...
}:
let
  mkDockerNetwork = import ./docker-network.nix;
  mkDockerBuild = import ./docker-build.nix;
  mkNotify = import ./notify.nix;
  telegramNotify = mkNotify { inherit pkgs; };
  projectPath = "/home/askold/src/DohlaRusnya";
  apiProjectPath = "${projectPath}/src/server/DohlaRusnya3.4.and.5/DohlaRusnya.Api";

  testRoot = "docker-dohly-test-root.target";
  testApiPath = "${apiProjectPath}/default.nix";
  testNetwork = "docker-network-dohly-test";
  testNetworkService = "${testNetwork}.service";
  testProxyPath = "${projectPath}/src/server/DohlaRusnya3.4.and.5/Proxy/default.nix";

  generalNetwork = "docker-network-dohly-general";
  generalNetworkService = "${generalNetwork}.service";

  frontendRepo = "/home/askold/src/tic-tac-toe/tictactoe";

  githubWebhook = pkgs.writeShellScriptBin "github-webhook" ''
    exec ${pkgs.python3}/bin/python3 -u ${pkgs.writeText "github-webhook.py" ''
      import http.server, json, hmac, hashlib, os, subprocess, sys
      SECRET = os.environ.get("GITHUB_WEBHOOK_SECRET", "")
      PORT = int(os.environ.get("WEBHOOK_PORT", "7400"))
      REPO = os.environ.get("REPO_PATH", "/home/askold/src/tic-tac-toe/tictactoe")
      TOKEN = os.environ.get("BOT_TOKEN", "")
      CID = os.environ.get("CHAT_ID", "")
      TID = os.environ.get("TOPIC_ID", "")
      def notify(msg):
          if TOKEN and CID:
              subprocess.run(["curl","-s","-X","POST",
                  "https://api.telegram.org/bot"+TOKEN+"/sendMessage",
                  "--data-urlencode","chat_id="+CID,
                  "--data-urlencode","message_thread_id="+TID,
                  "--data-urlencode","text="+msg], capture_output=True)
      class H(http.server.BaseHTTPRequestHandler):
          def do_POST(self):
              body = self.rfile.read(int(self.headers.get("Content-Length",0)))
              sig = self.headers.get("X-Hub-Signature-256","")
              exp = "sha256="+hmac.new(SECRET.encode(),body,hashlib.sha256).hexdigest()
              if SECRET and not hmac.compare_digest(sig,exp):
                  return self.send_error(403)
              if self.headers.get("X-GitHub-Event","")!="push":
                  return self.send_response(200)
              self.send_response(200); self.end_headers(); self.wfile.write(b"ok")
              try:
                  p=json.loads(body); br=p.get("ref","").replace("refs/heads/","")
                  nm=p.get("repository",{}).get("full_name","unknown")
                  lb=subprocess.run(["git","-C",REPO,"rev-parse","--abbrev-ref","HEAD"],
                      capture_output=True,text=True).stdout.strip()
                  if br!=lb: notify("[webhook] "+nm+"/"+br+" != local "+lb+", skip"); return
                  notify("[webhook] "+nm+"/"+br+" push, pulling...")
                  r=subprocess.run(["git","-C",REPO,"fetch","origin",br],capture_output=True,text=True)
                  if r.returncode!=0: notify("[webhook] fetch failed: "+r.stderr); return
                  loc=subprocess.run(["git","-C",REPO,"rev-parse","HEAD"],capture_output=True,text=True).stdout.strip()
                  rem=subprocess.run(["git","-C",REPO,"rev-parse","origin/"+br],capture_output=True,text=True).stdout.strip()
                  if loc==rem: notify("[webhook] already up to date"); return
                  log=subprocess.run(["git","-C",REPO,"log","--oneline",loc+"..origin/"+br],
                      capture_output=True,text=True).stdout.strip()
                  m=subprocess.run(["git","-C",REPO,"merge","--ff-only"],capture_output=True,text=True)
                  if m.returncode!=0: notify("[webhook] merge failed: "+m.stderr); return
                  b=subprocess.run(["sudo","systemctl","restart",
                      "docker-build-dohly-front-test.service"],capture_output=True,text=True).returncode
                  c=subprocess.run(["sudo","systemctl","restart",
                      "docker-dohly-front-test.service"],capture_output=True,text=True).returncode
                  if b==0 and c==0: notify("[webhook] done\n"+log)
                  else: notify("[webhook] restart failed build="+str(b)+" container="+str(c))
              except Exception as e: notify("[webhook] error: "+str(e))
          def log_message(self,f,*a): sys.stderr.write("[webhook] "+(f%a)+"\n")
      http.server.HTTPServer(("0.0.0.0",PORT),H).serve_forever()
    ''}
  '';

in
{
  config = lib.mkMerge [

    # TEST
    {
      # Networks
      systemd.services."${testNetwork}" = mkDockerNetwork {
        inherit pkgs;
        networkName = "dohly-test";
        root = testRoot;
      };

      systemd.targets."${testRoot}" = {
        unitConfig = {
          Description = "Root target for dohly project test";
        };
        wantedBy = [ "multi-user.target" ];
      };
    }

    (lib.mkIf config.batat.dohla.test.api.enable ({
      # PROXY
      # virtualisation.oci-containers.containers."dohly-proxy-test" = {
      #   image = "dohly-proxy-test";
      #   environmentFiles = [
      #     "/run/agenix/api-test"
      #     #"/home/askold/src/DohlaRusnya/src/server/DohlaRusnya3.4.and.5/DohlaRusnya.Api/.env"
      #   ];
      #   # dependsOn = [ "dohly-database" ];
      #   ports = [
      #     "0.0.0.0:7000:5000/tcp"
      #   ];
      #   log-driver = "journald";
      #   extraOptions = [
      #     "--network-alias=dohly-proxy-test"
      #     "--network=dohly-test"
      #     "--network=dohly-general"
      #   ];
      # };
      #
      # systemd.services."docker-dohly-proxy-test" = {
      #   serviceConfig = {
      #     Restart = lib.mkOverride 90 "always";
      #     RestartMaxDelaySec = lib.mkOverride 90 "1m";
      #     RestartSec = lib.mkOverride 90 "100ms";
      #     RestartSteps = lib.mkOverride 90 9;
      #   };
      #
      #   after = [
      #     "docker-build-dohly-proxy-test.service"
      #     testNetworkService
      #     generalNetworkService
      #   ];
      #
      #   requires = [
      #     "docker-build-dohly-proxy-test.service"
      #     testNetworkService
      #     generalNetworkService
      #   ];
      #
      #   partOf = [ testRoot ];
      #   wantedBy = [ testRoot ];
      # };
      #
      # systemd.services."docker-build-dohly-proxy-test" = mkDockerBuild {
      #   inherit pkgs;
      #   projectPath = testProxyPath;
      #   packageName = "proxy";
      #   envName = "test";
      #   root = testRoot;
      #   port = "7100";
      # };
      #
      # API
      virtualisation.oci-containers.containers."dohly-api-test" = {
        image = "dohly-api-test";
        environmentFiles = [
          "/run/agenix/api"
          # "/home/askold/src/DohlaRusnya/src/server/DohlaRusnya3.4.and.5/DohlaRusnya.Api/.env"
        ];
        dependsOn = [ "dohly-database" ];
        ports = [
          "0.0.0.0:7100:5000/tcp"
        ];
        log-driver = "journald";
        extraOptions = [
          "--network-alias=dohly-api-test"
          "--network=dohly-test"
          "--network=dohly-general"
        ];
      };

      systemd.services."docker-dohly-api-test" = {
        serviceConfig = {
          Restart = lib.mkOverride 90 "always";
          RestartMaxDelaySec = lib.mkOverride 90 "1m";
          RestartSec = lib.mkOverride 90 "100ms";
          RestartSteps = lib.mkOverride 90 9;
        };

        after = [
          # "docker-build-dohly-api-test.service"
          testNetworkService
          generalNetworkService
        ];

        requires = [
          # "docker-build-dohly-api-test.service"
          testNetworkService
          generalNetworkService
        ];

        partOf = [ testRoot ];
        wantedBy = [ testRoot ];
      };

      # systemd.services."docker-build-dohly-api-test" = mkDockerBuild {
      #   inherit pkgs;
      #   projectPath = testApiPath;
      #   packageName = "apiImage";
      #   envName = "test";
      #   root = testRoot;
      #   port = "7100";
      # };

    }))

    # FRONT
    (lib.mkIf config.batat.dohla.test.front.enable ({
      virtualisation.oci-containers.containers."dohly-front-test" = {
        image = "dohly-front-test:latest";
        environmentFiles = [
          "/run/agenix/front-test"
        ];
        dependsOn = [
          #  "dohly-api-test"
        ];
        ports = [
          "0.0.0.0:7200:3000/tcp"
        ];
        log-driver = "journald";
        extraOptions = [
          "--network-alias=dohly-front-test"
          "--network=dohly-test"
          "--network=dohly-general"
        ];
      };

      systemd.services."docker-dohly-front-test" = {
        serviceConfig = {
          Restart = lib.mkOverride 90 "always";
          RestartMaxDelaySec = lib.mkOverride 90 "1m";
          RestartSec = lib.mkOverride 90 "100ms";
          RestartSteps = lib.mkOverride 90 9;
        };

        after = [
          "docker-build-dohly-front-test.service"
          testNetworkService
          generalNetworkService
        ];

        requires = [
          "docker-build-dohly-front-test.service"
          testNetworkService
          generalNetworkService
        ];

        partOf = [ testRoot ];
        wantedBy = [ testRoot ];
      };

      systemd.services."docker-build-dohly-front-test" = {
        path = [ pkgs.docker ];
        serviceConfig = {
          Type = "oneshot";
          RemainAfterExit = true;
          TimeOutSec = 300;
        };
        script = ''
          cd ${frontendRepo}
          # docker build -t dohly-front-test:latest -f dev.dockerfile .
          docker build -t dohly-front-test:latest -f Dockerfile .
        '';
        partOf = [ testRoot ];
        wantedBy = [ testRoot ];
      };

      # Webhook service — replaces timer-based git-pull
      systemd.services."dohly-front-webhook" = {
        description = "GitHub webhook listener for frontend auto-deploy";
        wantedBy = [ "multi-user.target" ];
        after = [ "network-online.target" ];
        requires = [ "network-online.target" ];

        path = [
          pkgs.git
          pkgs.openssh
          pkgs.curl
          pkgs.systemd
          pkgs.sudo
        ];

        serviceConfig = {
          Type = "simple";
          User = "askold";
          Restart = "always";
          RestartSec = "5s";
          EnvironmentFile = "/run/agenix/telegram-bot";
          Environment = [
            "REPO_PATH=${frontendRepo}"
            "WEBHOOK_PORT=7400"
          ];
          # GITHUB_WEBHOOK_SECRET comes from /run/agenix/github-webhook (see below)
        };

        script = ''
          export GITHUB_WEBHOOK_SECRET=$(cat /run/agenix/github-webhook 2>/dev/null || echo "")
          exec ${githubWebhook}/bin/github-webhook
        '';
      };

      # Add webhook secret to agenix
      age.secrets.github-webhook = {
        file = inputs.mysecrets + "/github-webhook.age";
        owner = "askold";
      };

      security.sudo.extraRules = [
        {
          users = [ "askold" ];
          commands = [
            {
              command = "/run/current-system/sw/bin/systemctl restart docker-build-dohly-front-test.service";
              options = [ "NOPASSWD" ];
            }
            {
              command = "/run/current-system/sw/bin/systemctl restart docker-dohly-front-test.service";
              options = [ "NOPASSWD" ];
            }
          ];
        }
      ];

    }))
  ];
}
