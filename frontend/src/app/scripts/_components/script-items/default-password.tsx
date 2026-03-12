import type { Script } from "@/lib/types";

import { Separator } from "@/components/ui/separator";
import handleCopy from "@/components/handle-copy";
import { Button } from "@/components/ui/button";

export default function DefaultPassword({ item }: { item: Script }) {
  const { username, password } = item.default_credentials;
  const hasDefaultLogin = username || password;

  if (!hasDefaultLogin)
    return null;

  const copyCredential = (type: "username" | "password") => {
    handleCopy(type, item.default_credentials[type] ?? "");
  };

  return (
    <div className="mt-4 rounded-lg border shadow-sm">
      <div className="flex gap-3 px-4 py-2 bg-accent/25">
        <h2 className="text-lg font-semibold">Default Login Credentials</h2>
      </div>
      <Separator className="w-full" />
      <div className="flex flex-col gap-2 p-4">
        <p className="mb-2 text-sm">
          You can use the following credentials to login to the
          {" "}
          {item.name}
          {" "}
          {item.type}
          .
        </p>
        {["username", "password"].map((type) => {
          const value = item.default_credentials[type as "username" | "password"];
          return value && value.trim() !== ""
            ? (
                <div key={type} className="text-sm">
                  {type.charAt(0).toUpperCase() + type.slice(1)}
                  :
                  {" "}
                  <Button variant="secondary" size="null" onClick={() => copyCredential(type as "username" | "password")}>
                    {value}
                  </Button>
                </div>
              )
            : null;
        })}
      </div>
    </div>
  );
}
