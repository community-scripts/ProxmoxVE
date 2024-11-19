import handleCopy from "@/components/handleCopy";
import { Button } from "@/components/ui/button";
import { Separator } from "@/components/ui/separator";
import { Script } from "@/lib/types";

export default function DefaultPassword({ item }: { item: Script }) {
  const { username, password } = item.default_credentials;
  const hasDefaultLogin = username && password;

  if (!hasDefaultLogin) return null;

  const copyCredential = (type: "username" | "password") => {
    handleCopy(type, item.default_credentials[type] ?? "");
  };

  return (
    <div className="mt-4 rounded-lg border bg-accent/50">
      <div className="flex gap-3 px-4 py-2">
        <h2 className="text-lg font-semibold">Default Login Credentials</h2>
      </div>
      <Separator className="w-full" />
      <div className="flex flex-col gap-2 p-4">
        <p className="mb-2 text-sm">
          You can use the following credentials to login to the {item.name}{" "}
          {item.type}.
        </p>
        {["username", "password"].map((type) => (
          <div key={type} className="text-sm">
            {type.charAt(0).toUpperCase() + type.slice(1)}:{" "}
            <Button
              variant="secondary"
              size="null"
              onClick={() => copyCredential(type as "username" | "password")}
            >
              {item.default_credentials[type as "username" | "password"]}
            </Button>
          </div>
        ))}
      </div>
    </div>
  );
}
