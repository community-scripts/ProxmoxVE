import { useEffect, useState } from "react";
import { Info } from "lucide-react";

import type { Script } from "@/lib/types";

import { Tabs, TabsContent, TabsList, TabsTrigger } from "@/components/ui/tabs";
import { Alert, AlertDescription } from "@/components/ui/alert";
import CodeCopyButton from "@/components/ui/code-copy-button";
import { basePath } from "@/config/site-config";

import { getDisplayValueFromType } from "../script-info-blocks";

function getInstallCommand(scriptPath = "", isAlpine = false, useGitea = false) {
  const githubUrl = `https://raw.githubusercontent.com/community-scripts/${basePath}/main/${scriptPath}`;
  const giteaUrl = `https://git.community-scripts.org/community-scripts/${basePath}/raw/branch/main/${scriptPath}`;
  const dockerComposeUrl = `https://raw.githubusercontent.com/community-scripts/${basePath}/main/${scriptPath}`;
  const helmUrl = `https://raw.githubusercontent.com/community-scripts/${basePath}/main/${scriptPath}`;
  const url = useGitea ? giteaUrl : githubUrl;
  // return isAlpine ? `bash -c "$(curl -fsSL ${url})"` : `bash -c "$(curl -fsSL ${url})"`;
  return isAlpine ? `bash -c "$(curl -fsSL ${url})"` : `bash -c "$(curl -fsSL ${url})"`;
}

// function getDockerComposeUrl(dockerComposePath: string, useGitea = false) {
//   const githubUrl = `https://raw.githubusercontent.com/community-scripts/${basePath}/main/${dockerComposePath}`;
//   const giteaUrl = `https://git.community-scripts.org/community-scripts/${basePath}/raw/branch/main/${dockerComposePath}`;
  
//   return useGitea ? giteaUrl : githubUrl;
// }

function getDockerComposeUrl(dockerComposePath: string) {
  // Full URL → langsung pakai
  if (dockerComposePath.startsWith("http://") || dockerComposePath.startsWith("https://")) {
    return dockerComposePath;
  }

  // Normalisasi basePath (misalnya "ProxmoxVE" → "/ProxmoxVE")
  let prefix = "";
  if (basePath && basePath !== "/") {
    prefix = basePath.startsWith("/") ? basePath : `/${basePath}`;
  }

  // Kalau path sudah diawali "/" → tempel setelah basePath
  if (dockerComposePath.startsWith("/")) {
    return `${prefix}${dockerComposePath}`;
  }

  // Default: "/<basePath>/<path>"
  return `${prefix}/${dockerComposePath}`;
}

export default function InstallCommand({ item }: { item: Script }) {
  const alpineScript = item.install_methods.find(method => method.type === "alpine");
  const defaultScript = item.install_methods.find(method => method.type === "default");

  const [dockerComposeContent, setDockerComposeContent] = useState<string | null>(null);
  const [dockerComposeLoading, setDockerComposeLoading] = useState(false);
  const [dockerComposeError, setDockerComposeError] = useState<string | null>(null);

  useEffect(() => {
    if (!item.docker_compose_path) {
      setDockerComposeContent(null);
      setDockerComposeError(null);
      return;
    }

    const url = getDockerComposeUrl(item.docker_compose_path);
    console.log("[DockerCompose] fetching:", url);

    setDockerComposeLoading(true);
    setDockerComposeError(null);

    fetch(url)
      .then(res => {
        if (!res.ok) {
          throw new Error(`HTTP ${res.status} ${res.statusText}`);
        }
        return res.text();
      })
      .then(text => setDockerComposeContent(text))
      .catch(err => {
        console.error("Failed to load docker compose manifest from", url, err);
        setDockerComposeError("Failed to load Docker Compose manifest.");
      })
      .finally(() => setDockerComposeLoading(false));
  }, [item.docker_compose_path]);

  const renderInstructions = (isAlpine = false) => (
    <>
      <p className="text-sm mt-2">
        {isAlpine
          ? (
              <>
                As an alternative option, you can use Alpine Linux and the
                {" "}
                {item.name}
                {" "}
                package to create a
                {" "}
                {item.name}
                {" "}
                {getDisplayValueFromType(item.type)}
                {" "}
                container with faster creation time and minimal system resource usage.
                You are also obliged to adhere to updates provided by the package maintainer.
              </>
            )
          : item.type === "pve"
            ? (
                <>
                  To use the
                  {" "}
                  {item.name}
                  {" "}
                  script, run the command below **only** in the Proxmox VE Shell. This script is
                  intended for managing or enhancing the host system directly.
                </>
              )
          : item.type === "dc"
            ? (
                <>
                  To use the
                  {" "}
                  {item.name}
                  {" "}
                  script, run the command below **only** in the Proxmox VE Shell. This script is
                  intended for managing or enhancing the host system directly.
                </>
              )
          : item.type === "helm"
          ? (
              <>
                To use the
                {" "}
                {item.name}
                {" "}
                script, run the command below **only** in the Proxmox VE Shell. This script is
                intended for managing or enhancing the host system directly.
              </>
            )
          : item.type === "addon"
          ? (
              <>
                This script enhances an existing setup. You can use it inside a running LXC container or directly on the
                Proxmox VE host to extend functionality with
                {" "}
                {item.name}
                .
              </>
            )
          : (
              <>
                To create a new Proxmox VE
                {" "}
                {item.name}
                {" "}
                {getDisplayValueFromType(item.type)}
                , run the command below in the
                Proxmox VE Shell.
              </>
            )
          }
      </p>
      {isAlpine && (
        <p className="mt-2 text-sm">
          To create a new Proxmox VE Alpine-
          {item.name}
          {" "}
          {getDisplayValueFromType(item.type)}
          , run the command below in
          the Proxmox VE Shell.
        </p>
      )}
    </>
  );

  const renderGiteaInfo = () => (
    <Alert className="mt-3 mb-3">
      <Info className="h-4 w-4" />
      <AlertDescription className="text-sm">
        <strong>When to use Gitea:</strong>
        {" "}
        GitHub may have issues including slow connections, delayed updates after bug
        fixes, no IPv6 support, API rate limits (60/hour). Use our Gitea mirror as a reliable alternative when
        experiencing these issues.
      </AlertDescription>
    </Alert>
  );

  // const renderDockercomposeInfo = () => (
  //   <Alert className="mt-3 mb-3">
  //     <Info className="h-4 w-4" />
  //     <AlertDescription className="text-sm">
  //       <strong>When to use Gitea:</strong>
  //       {" "}
  //       GitHub may have issues including slow connections, delayed updates after bug
  //       fixes, no IPv6 support, API rate limits (60/hour). Use our Gitea mirror as a reliable alternative when
  //       experiencing these issues.
  //     </AlertDescription>
  //   </Alert>
  // );

  const renderDockercomposeInfo = () => (
    <Alert className="mt-3 mb-3">
      <Info className="h-4 w-4" />
      <AlertDescription className="text-sm">
        <strong>How to use this Docker Compose manifest:</strong>{" "}
        Save the content below as <code>docker-compose.yml</code> in an empty
        folder, then run <code>docker compose up -d</code> (or{" "}
        <code>docker-compose up -d</code> on older setups).
      </AlertDescription>
    </Alert>
  );

  const renderScriptTabs = (useGitea = false) => {
    if (alpineScript) {
      return (
        <Tabs defaultValue="default" className="mt-2 w-full max-w-4xl">
          <TabsList>
            <TabsTrigger value="default">Default</TabsTrigger>
            <TabsTrigger value="alpine">Alpine Linux</TabsTrigger>
          </TabsList>
          <TabsContent value="default">
            {renderInstructions()}
            <CodeCopyButton>{getInstallCommand(defaultScript?.script, false, useGitea)}</CodeCopyButton>
          </TabsContent>
          <TabsContent value="alpine">
            {renderInstructions(true)}
            <CodeCopyButton>{getInstallCommand(alpineScript.script, true, useGitea)}</CodeCopyButton>
          </TabsContent>
        </Tabs>
      );
    }
    else if (defaultScript?.script) {
      return (
        <>
          {renderInstructions()}
          <CodeCopyButton>{getInstallCommand(defaultScript.script, false, useGitea)}</CodeCopyButton>
        </>
      );
    }
    return null;
  };

    const renderDockerComposeTab = () => {
    if (!item.docker_compose_path) {
      return (
        <>
          {renderDockercomposeInfo()}
          <p className="text-sm mt-2">
            No Docker Compose manifest is defined for this script yet.
          </p>
        </>
      );
    }

    return (
      <>
        {renderDockercomposeInfo()}
        {dockerComposeLoading && (
          <p className="text-sm mt-2">Loading Docker Compose manifest...</p>
        )}
        {dockerComposeError && (
          <p className="text-sm mt-2 text-red-500">
            {dockerComposeError}
          </p>
        )}
        {dockerComposeContent && (
          <>
            <p className="text-sm mt-2">
              The manifest below is tailored for{" "}
              <strong>{item.name}</strong>. Adjust volumes, ports, and
              environment variables as needed.
            </p>
            <CodeCopyButton>{dockerComposeContent}</CodeCopyButton>
          </>
        )}
      </>
    );
  };

  return (
    <div className="p-4">
      <Tabs defaultValue="github" className="w-full max-w-4xl">
        <TabsList>
          <TabsTrigger value="github">GitHub</TabsTrigger>
          <TabsTrigger value="gitea">Gitea</TabsTrigger>
          <TabsTrigger value="dc">Docker Compose</TabsTrigger>
          <TabsTrigger value="helm">Helm</TabsTrigger>
        </TabsList>

        <TabsContent value="github">
          {renderScriptTabs(false)}
        </TabsContent>

        <TabsContent value="gitea">
          {renderGiteaInfo()}
          {renderScriptTabs(true)}
        </TabsContent>

        <TabsContent value="dc">
          {renderDockerComposeTab()}
        </TabsContent>

        <TabsContent value="helm">
          {renderScriptTabs(false)}
        </TabsContent>
      </Tabs>
    </div>
  );
}
