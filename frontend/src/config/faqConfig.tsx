export const FAQ_Items = [
  {
    id: '1',
    title: 'Git pull vs tarball install',
    content: 'As you probably know, git repositories contain code that is constantly changing. Pulling from a git repository means that you are getting the latest version of development code. This is not always the best idea as live repository often contains unfinished code or code containing bugs. We are using release tarballs because they are safer and most likely don\'t contain that many bugs or at least not obvious ones.',
  },
  {
    id: '2',
    title: 'HTTP vs HTTPS in LXC',
    content: 'Many of the applications installed by our scripts are available via HTTP and HTTPS. Since there are so many different application frameworks and use cases, we default to HTTP install where enabling of HTTPS is left to the user, unless its impossible to run the application without HTTPS. Enabling HTTPS often requires manual steps which we cant cover with simple bash script. We usually point to the application documentation for such LXCs.',
  },
  {
    id: '3',
    title: 'Application Documentation',
    content: 'Most of the applications installed by our scripts have their own documentation. We try to point to the official documentation as much as possible. If you find that script web page is missing a link to the official documentation (for applications that have it), please let us know and we will fix it.',
  },
  {
    id: '4',
    title: 'Bugs in our LXC scripts',
    content: 'We are bunch of individuals doing this in our free time and unfortunately bugs happen. Be it our own doing or it\'s a change in the application we\'re installing. If you find a bug in our LXC scripts, please let us know. We are constantly working on improving our scripts and we appreciate any feedback. You can report bugs on our GitHub page.',
  },
  {
    id: '5',
    title: 'Application not updating to the latest version',
    content: 'As we\'re using the github release system to pull the latest tarballs, this can mean that either there is bug in the repository itself (can happen if developer changes the release naming scheme) or it\'s a unintended bug in our script. This can happen if we deliberately stop the update of the application at specific version. This happens when there is a breaking change introduced by the version you tried to update and we don\'t want you to lose your LXC/data. This also happens if we decide to stop supporting the application until developer fixes the isses plaguing the version.',
  },
  {
    id: '6',
    title: "I'm getting 502 Bad Gateway error while trying to access the application",
    content: 'This error can happen for a number of reasons. The most common reason is that the application is not running or is not configured correctly. Please check the application logs for more information. If you are using a reverse proxy, please check the reverse proxy logs as well. If you are still having issues, please let us know and we will try to help you.',
  },
  {
    id: '7',
    title: 'Errors while running the script',
    content: 'If a script fails to run, please run it in Verbose mode. Normal mode suppresses all the output and only show progress messages. Verbose mode shows all the output and is useful for debugging.',
  },
];