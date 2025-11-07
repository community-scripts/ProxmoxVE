import { useEffect, useState } from "react";
import { Info } from "lucide-react";

import type { Script } from "@/lib/types";

import { Tabs, TabsContent, TabsList, TabsTrigger } from "@/components/ui/tabs";
import { Alert, AlertDescription } from "@/components/ui/alert";
import CodeCopyButton from "@/components/ui/code-copy-button";
import { basePath } from "@/config/site-config";

function buildStaticUrl(path: string) {
  if (path.startsWith("http://") || path.startsWith("https://")) {
    return path;
  }

  let prefix = "";
  if (basePath && basePath !== "/") {
    prefix = basePath.startsWith("/") ? basePath : `/${basePath}`;
  }

  if (path.startsWith("/")) {
    return `${prefix}${path}`;
  }

  return `${prefix}/${path}`;
}

export default function InstallCommand({ item }: { item: Script }) {
  const manifest = item.manifest_path ?? {};
  const slug = item.slug ?? "my-app";

  const [binaryContent, setBinaryContent] = useState<string | null>(null);
  const [binaryLoading, setBinaryLoading] = useState(false);
  const [binaryError, setBinaryError] = useState<string | null>(null);

  const [dockerComposeContent, setDockerComposeContent] = useState<
    string | null
  >(null);
  const [dockerComposeLoading, setDockerComposeLoading] = useState(false);
  const [dockerComposeError, setDockerComposeError] = useState<string | null>(
    null
  );

  const [k8sContent, setK8sContent] = useState<string | null>(null);
  const [k8sLoading, setK8sLoading] = useState(false);
  const [k8sError, setK8sError] = useState<string | null>(null);

  const [helmContent, setHelmContent] = useState<string | null>(null);
  const [helmLoading, setHelmLoading] = useState(false);
  const [helmError, setHelmError] = useState<string | null>(null);

  const [tfContent, setTfContent] = useState<string | null>(null);
  const [tfLoading, setTfLoading] = useState(false);
  const [tfError, setTfError] = useState<string | null>(null);

  const hasBinary = !!manifest.binary;
  const hasDockerCompose = !!manifest.docker_compose;
  const hasKubernetes = !!manifest.kubernetes;
  const hasHelm = !!manifest.helm;
  const hasTerraform = !!manifest.terraform;

  const defaultTab =
    (hasBinary && "binary") ||
    (hasDockerCompose && "docker_compose") ||
    (hasHelm && "helm") ||
    (hasKubernetes && "kubernetes") ||
    (hasTerraform && "terraform") ||
    "binary";

  function loadTextFile(
    path: string | null | undefined,
    setContent: (v: string | null) => void,
    setLoading: (v: boolean) => void,
    setError: (v: string | null) => void
  ) {
    if (!path) {
      setContent(null);
      setError(null);
      setLoading(false);
      return;
    }

    const url = buildStaticUrl(path);
    console.log("[Manifest] fetching:", url);

    setLoading(true);
    setError(null);

    fetch(url)
      .then((res) => {
        if (!res.ok) {
          throw new Error(`HTTP ${res.status} ${res.statusText}`);
        }
        return res.text();
      })
      .then((text) => setContent(text))
      .catch((err) => {
        console.error("Failed to load manifest from", url, err);
        setError("Failed to load manifest.");
      })
      .finally(() => setLoading(false));
  }

  // Load masing-masing manifest, hanya jika path ada
  useEffect(() => {
    loadTextFile(
      manifest.binary,
      setBinaryContent,
      setBinaryLoading,
      setBinaryError
    );
  }, [manifest.binary]);

  useEffect(() => {
    loadTextFile(
      manifest.docker_compose,
      setDockerComposeContent,
      setDockerComposeLoading,
      setDockerComposeError
    );
  }, [manifest.docker_compose]);

  useEffect(() => {
    loadTextFile(
      manifest.kubernetes,
      setK8sContent,
      setK8sLoading,
      setK8sError
    );
  }, [manifest.kubernetes]);

  useEffect(() => {
    loadTextFile(
      manifest.helm,
      setHelmContent,
      setHelmLoading,
      setHelmError
    );
  }, [manifest.helm]);

  useEffect(() => {
    loadTextFile(
      manifest.terraform,
      setTfContent,
      setTfLoading,
      setTfError
    );
  }, [manifest.terraform]);

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

  return (
    <div className="p-4">
      <Tabs defaultValue={defaultTab} className="w-full max-w-4xl">
        <TabsList>
          {hasBinary && <TabsTrigger value="binary">Script</TabsTrigger>}
          {hasDockerCompose && (
            <TabsTrigger value="docker_compose">Docker Compose</TabsTrigger>
          )}
          {hasHelm && <TabsTrigger value="helm">Helm</TabsTrigger>}
          {hasKubernetes && (
            <TabsTrigger value="kubernetes">Kubernetes</TabsTrigger>
          )}
          {hasTerraform && (
            <TabsTrigger value="terraform">Terraform</TabsTrigger>
          )}
        </TabsList>

        {hasBinary && (
          <TabsContent value="binary">
            <p className="text-sm mt-2">
              Installation script for <strong>{item.name}</strong>, loaded from{" "}
              <code>{manifest.binary}</code>.
            </p>
            {binaryLoading && (
              <p className="text-sm mt-2">Loading script manifest...</p>
            )}
            {binaryError && (
              <p className="text-sm mt-2 text-red-500">{binaryError}</p>
            )}
            {binaryContent && <CodeCopyButton>{binaryContent}</CodeCopyButton>}
          </TabsContent>
        )}

        {hasDockerCompose && (
          <TabsContent value="docker_compose">
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
                  Manifest loaded from <code>{manifest.docker_compose}</code>.
                  Adjust ports, volumes, and environment variables as needed.
                </p>
                <CodeCopyButton>{dockerComposeContent}</CodeCopyButton>
              </>
            )}
          </TabsContent>
        )}

        {hasHelm && (
          <TabsContent value="helm">
            <Alert className="mt-3 mb-3">
              <Info className="h-4 w-4" />
              <AlertDescription className="text-sm">
                Helm-related manifest for <strong>{item.name}</strong>, loaded
                from <code>{manifest.helm}</code>. Use it as needed in your
                Helm workflow (values file, template, atau dokumentasi).
              </AlertDescription>
            </Alert>
            {helmLoading && (
              <p className="text-sm mt-2">Loading Helm manifest...</p>
            )}
            {helmError && (
              <p className="text-sm mt-2 text-red-500">{helmError}</p>
            )}
            {helmContent && <CodeCopyButton>{helmContent}</CodeCopyButton>}
          </TabsContent>
        )}

        {hasKubernetes && (
          <TabsContent value="kubernetes">
            <p className="text-sm mt-2">
              Kubernetes manifest for <strong>{item.name}</strong>, loaded from{" "}
              <code>{manifest.kubernetes}</code>.
            </p>
            {k8sLoading && (
              <p className="text-sm mt-2">Loading Kubernetes manifest...</p>
            )}
            {k8sError && (
              <p className="text-sm mt-2 text-red-500">{k8sError}</p>
            )}
            {k8sContent && <CodeCopyButton>{k8sContent}</CodeCopyButton>}
          </TabsContent>
        )}

        {hasTerraform && (
          <TabsContent value="terraform">
            <p className="text-sm mt-2">
              Terraform configuration for <strong>{item.name}</strong>, loaded
              from <code>{manifest.terraform}</code>.
            </p>
            {tfLoading && (
              <p className="text-sm mt-2">Loading Terraform manifest...</p>
            )}
            {tfError && (
              <p className="text-sm mt-2 text-red-500">{tfError}</p>
            )}
            {tfContent && <CodeCopyButton>{tfContent}</CodeCopyButton>}
          </TabsContent>
        )}
      </Tabs>
    </div>
  );
}
