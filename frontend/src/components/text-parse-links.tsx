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
          className="bg-secondary py-1 px-2 rounded-lg inline-flex items-center gap-2"
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
                className="inline-flex items-center gap-1 text-blue-600 dark:text-blue-400 hover:underline font-medium transition-colors"
              >
                {urlPart}
                <ExternalLink className="size-3" />
              </a>
            );
          }
          return <Fragment key={`plain-${codeIndex}-${urlIndex}`}>{urlPart}</Fragment>;
        })}
      </Fragment>
    );
  });
}
