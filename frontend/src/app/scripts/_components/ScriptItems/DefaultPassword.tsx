import handleCopy from "@/components/handleCopy";
import { Button } from "@/components/ui/button";
import { Separator } from "@/components/ui/separator";
import { Script } from "@/lib/types";

export default function DefaultPassword({ item }: { item: Script }) {
  const hasDefaultLogin =
    item.default_credentials.username && item.default_credentials.password;

  return (
    <div>
      {hasDefaultLogin && (
        <div className="mt-4 rounded-lg border bg-accent/50">
          <div className="flex gap-3 px-4 py-2">
            <h2 className="text-lg font-semibold">Default Login Credentials</h2>
          </div>
          <Separator className="w-full"></Separator>
          <div className="flex flex-col gap-2 p-4">
            <p className="mb-2 text-sm">
              You can use the following credentials to login to the {""}
              {item.name} {item.type}.
            </p>
            <div className="text-sm">
              Username:{" "}
              <Button
                variant={"secondary"}
                size={"null"}
                onClick={() =>
                  handleCopy(
                    "username",
                    item.default_credentials.username ?? "",
                  )
                }
              >
                {item.default_credentials.username}
              </Button>
            </div>
            <div className="text-sm">
              Password:{" "}
              <Button
                variant={"secondary"}
                size={"null"}
                onClick={() =>
                  handleCopy(
                    "password",
                    item.default_credentials.password ?? "",
                  )
                }
              >
                {item.default_credentials.password}
              </Button>
            </div>
          </div>
        </div>
      )}
    </div>
  );
}
