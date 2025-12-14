import { ClipboardIcon, ExternalLink } from "lucide-react";
import { Fragment } from "react";

import handleCopy from "./handle-copy";

const URL_PATTERN = /(https?:\/\/[^\s,]+)/;
const CODE_PATTERN = /`([^`]*)`/;

export default function TextParseLinks(text: string) {
  const codeParts = text.split(CODE_PATTERN);

  return codeParts.map((part: string, codeIndex: number) => {
    if (codeIndex % 2 === 1) {
      return (
        <span
          key={`code-${codeIndex}`}
          className="inline-flex items-center gap-2 rounded-lg bg-secondary px-2 py-1"
        >
          {part}
          <ClipboardIcon
            className="size-3 cursor-pointer"
            onClick={() => handleCopy("command", part)}
          />
        </span>
      );
    }

    const urlParts = part.split(URL_PATTERN);

    return (
      <Fragment key={`text-${codeIndex}`}>
        {urlParts.map((urlPart: string, urlIndex: number) => {
          if (urlIndex % 2 === 1) {
            return (
              <a
                key={`url-${codeIndex}-${urlIndex}`}
                href={urlPart}
                target="_blank"
                rel="noopener noreferrer"
                className="inline-flex items-center gap-1 font-medium text-blue-600 transition-colors hover:underline dark:text-blue-400"
              >
                {urlPart}
                <ExternalLink className="size-3" />
              </a>
            );
          }
          return (
            <Fragment key={`plain-${codeIndex}-${urlIndex}`}>
              {urlPart}
            </Fragment>
          );
        })}
      </Fragment>
    );
  });
}
