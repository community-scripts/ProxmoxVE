import CodeCopyButton from "@/components/ui/code-copy-button";
import { Tabs, TabsContent, TabsList, TabsTrigger } from "@/components/ui/tabs";
import { Alert, AlertDescription } from "@/components/ui/alert";
import { Info } from "lucide-react";
import { basePath } from "@/config/siteConfig";
import { Script } from "@/lib/types";
import { getDisplayValueFromType } from "../ScriptInfoBlocks";

const getInstallCommand = (scriptPath = "", isAlpine = false, useGitea = false) => {
  const githubUrl = `https://raw.githubusercontent.com/community-scripts/${basePath}/main/${scriptPath}`;
  const giteaUrl = `https://git.community-scripts.org/community-scripts/${basePath}/raw/branch/main/${scriptPath}`;
  const url = useGitea ? giteaUrl : githubUrl;
  return `bash -c "$(curl -fsSL ${url})"`;
};

export default function InstallCommand({ item }: { item: Script }) {
  const alpineScript = item.install_methods.find((method) => method.type === "alpine");
  const defaultScript = item.install_methods.find((method) => method.type === "default");

  const renderInstructions = (isAlpine = false) => (
    <>
      <p className="text-sm mt-2">
        {isAlpine ? (
          <>
            As an alternative option, you can use Alpine Linux and the {item.name} package to create a {item.name}{" "}
            {getDisplayValueFromType(item.type)} container with faster creation time and minimal system resource usage.
            You are also obliged to adhere to updates provided by the package maintainer.
          </>
        ) : item.type === "pve" ? (
          <>
            To use the {item.name} script, run the command below **only** in the Proxmox VE Shell. This script is
            intended for managing or enhancing the host system directly.
          </>
        ) : item.type === "addon" ? (
          <>
            This script enhances an existing setup. You can use it inside a running LXC container or directly on the
            Proxmox VE host to extend functionality with {item.name}.
          </>
        ) : (
          <>
            To create a new Proxmox VE {item.name} {getDisplayValueFromType(item.type)}, run the command below in the
            Proxmox VE Shell.
          </>
        )}
      </p>
      {isAlpine && (
        <p className="mt-2 text-sm">
          To create a new Proxmox VE Alpine-{item.name} {getDisplayValueFromType(item.type)}, run the command below in
          the Proxmox VE Shell.
        </p>
      )}
    </>
  );

  const renderGiteaInfo = () => (
    <Alert className="mt-3 mb-3">
      <Info className="h-4 w-4" />
      <AlertDescription className="text-sm">
        <strong>When to use Gitea:</strong> GitHub may have issues including slow connections, delayed updates after bug
        fixes, no IPv6 support, API rate limits (60/hour). Use our Gitea mirror as a reliable alternative when
        experiencing these issues.
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
    } else if (defaultScript?.script) {
      return (
        <>
          {renderInstructions()}
          <CodeCopyButton>{getInstallCommand(defaultScript.script, false, useGitea)}</CodeCopyButton>
        </>
      );
    }
    return null;
  };

  return (
    <div className="p-4">
      <Tabs defaultValue="github" className="w-full max-w-4xl">
        <TabsList>
          <TabsTrigger value="github">GitHub</TabsTrigger>
          <TabsTrigger value="gitea">Gitea</TabsTrigger>
        </TabsList>
        <TabsContent value="github">
          {renderScriptTabs(false)}
        </TabsContent>
        <TabsContent value="gitea">
          {renderGiteaInfo()}
          {renderScriptTabs(true)}
        </TabsContent>
      </Tabs>
    </div>
  );
}
