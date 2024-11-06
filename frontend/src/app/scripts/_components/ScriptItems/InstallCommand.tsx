import CodeCopyButton from "@/components/ui/code-copy-button";
import { Tabs, TabsContent, TabsList, TabsTrigger } from "@/components/ui/tabs";
import { Script } from "@/lib/types";

const generateInstallCommand = (script?: string) => {
  return `bash -c "$(wget -qLO - https://github.com/community-scripts/ProxmoxVE/raw/main/${script})"`;
}

export default function InstallCommand({ item }: { item: Script }) {
  const alpineScript = item.install_methods.find(
    (method) => method.type === "alpine",
  );

  const defaultScript = item.install_methods.find(
    (method) => method.type === "default"
  );

  const renderInstructions = (isAlpine = false) => (
    <>
      <p className="text-sm mt-2">
        {isAlpine ? (
          <>
            As an alternative option, you can use Alpine Linux and the {item.name}{" "}
            package to create a {item.name} {item.type} container with faster
            creation time and minimal system resource usage. You are also
            obliged to adhere to updates provided by the package maintainer.
          </>
        ) : item.type ? (
          <>
            To create a new Proxmox VE {item.name} {item.type}, run the command
            below in the Proxmox VE Shell.
          </>
        ) : (
          <>To use the {item.name} script, run the command below in the shell.</>
        )}
      </p>
      {isAlpine && (
        <p className="mt-2 text-sm">
          To create a new Proxmox VE Alpine-{item.name} {item.type}, run the command
          below in the Proxmox VE Shell
        </p>
      )}
    </>
  );

  return (
    <div className="p-4">
      {alpineScript ? (
        <Tabs defaultValue="default" className="mt-2 w-full max-w-4xl">
          <TabsList>
            <TabsTrigger value="default">Default</TabsTrigger>
            <TabsTrigger value="alpine">Alpine Linux</TabsTrigger>
          </TabsList>
          <TabsContent value="default">
            {renderInstructions()}
            <CodeCopyButton>{generateInstallCommand(defaultScript?.script)}</CodeCopyButton>
          </TabsContent>
          <TabsContent value="alpine">
            {renderInstructions(true)}
            <CodeCopyButton>
              {generateInstallCommand(alpineScript.script)}
            </CodeCopyButton>
          </TabsContent>
        </Tabs>
      ) : defaultScript?.script ? (
        <>
          {renderInstructions()}
          <CodeCopyButton>
            {generateInstallCommand(defaultScript.script)}
          </CodeCopyButton>
        </>
      ) : null}
    </div>
  );
}
