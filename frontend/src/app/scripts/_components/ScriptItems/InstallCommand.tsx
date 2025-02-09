import CodeCopyButton from "@/components/ui/code-copy-button";
import { Tabs, TabsContent, TabsList, TabsTrigger } from "@/components/ui/tabs";
import { basePath } from "@/config/siteConfig";
import Link from "next/link";
import { Button } from "@/components/ui/button";
import { ArrowRightIcon, ExternalLink } from "lucide-react";

import { Script } from "@/lib/types";
import { getDisplayValueFromType } from "../ScriptInfoBlocks";

function CustomArrowRightIcon() {
  return <ArrowRightIcon className="h-4 w-4" width={1} />;
}

const getInstallCommand = (slug?: string, isAlpine = false) => {
  return `scripts-cli launch ${slug} your-instance-name`;
};

export default function InstallCommand({ item }: { item: Script }) {
  const alpineScript = item.install_methods.find(
    (method) => method.type === "alpine",
  );

  const defaultScript = item.install_methods.find(
    (method) => method.type === "default",
  );

  console.log(item);

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
            To create a new Incus {item.name}{" "}
            {getDisplayValueFromType(item.type)}, run the command below in a terminal.
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
              {getInstallCommand(item.slug)}
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
            {getInstallCommand(item.slug)}
          </CodeCopyButton>
                    	<Link href="/install">
								<Button
									size="lg"
									variant="expandIcon"
									Icon={CustomArrowRightIcon}
									iconPlacement="right"
                  data-umami-event="click-install"
									className="hover: my-3"
								>
									How to install scripts-cli
								</Button>
							</Link>
        </>
      ) : null}
    </div>
  );
}
