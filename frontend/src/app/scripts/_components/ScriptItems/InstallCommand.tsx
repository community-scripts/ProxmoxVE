import CodeCopyButton from "@/components/ui/code-copy-button";
import { Tabs, TabsContent, TabsList, TabsTrigger } from "@/components/ui/tabs";
import { basePath } from "@/config/siteConfig";
import { Script } from "@/lib/types";
import { getDisplayValueFromType } from "../ScriptInfoBlocks";

const getInstallCommand = (scriptPath?: string, isAlpine = false) => {
  return `bash -c "$(wget -q${isAlpine ? "" : "L"}O - https://github.com/community-scripts/${basePath}/raw/main/${scriptPath})"`;
};

export default function InstallCommand({ item }: { item: Script }) {
  const alpineScript = item.install_methods.find(
    (method) => method.type === "alpine",
  );

  const defaultScript = item.install_methods.find(
    (method) => method.type === "default",
  );

  const renderInstructions = (isAlpine = false) => (
    <>
      <p className="text-sm mt-2">
        {isAlpine ? (
          <>
            As an alternative option, you can use Alpine Linux and the{" "}
            {item.name} package to create a {item.name}{" "}
            {getDisplayValueFromType(item.type)} container with faster creation
            time and minimal system resource usage. You are also obliged to
            adhere to updates provided by the package maintainer.
          </>
        ) : item.type == "misc" ? (
          <>
            To use the {item.name} script, run the command below in the shell.
          </>
        ) : (
          <>
            {" "}
            To create a new Proxmox VE {item.name}{" "}
            {getDisplayValueFromType(item.type)}, run the command below in the
            Proxmox VE Shell.
          </>
        )}
      </p>
      {isAlpine && (
        <p className="mt-2 text-sm">
          To create a new Proxmox VE Alpine-{item.name}{" "}
          {getDisplayValueFromType(item.type)}, run the command below in the
          Proxmox VE Shell
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
            <CodeCopyButton>
              {getInstallCommand(defaultScript?.script)}
            </CodeCopyButton>
          </TabsContent>
          <TabsContent value="alpine">
            {renderInstructions(true)}
            <CodeCopyButton>
              {getInstallCommand(alpineScript.script, true)}
            </CodeCopyButton>
          </TabsContent>
        </Tabs>
      ) : defaultScript?.script ? (
        <>
          {renderInstructions()}
          <CodeCopyButton>
            {getInstallCommand(defaultScript.script)}
          </CodeCopyButton>
        </>
      ) : null}
    </div>
  );
}
