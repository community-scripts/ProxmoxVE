# Proxmox VE Helper-Scripts Frontend

> 🚀 **Modern frontend for the Community-Scripts Proxmox VE Helper-Scripts repository**

A comprehensive, user-friendly interface built with Next.js that provides access to 300+ automation scripts for Proxmox Virtual Environment management. This frontend serves as the official website for the Community-Scripts organization's Proxmox VE Helper-Scripts repository.

![Next.js](https://img.shields.io/badge/Next.js-15.2.4-black?style=flat-square&logo=next.js)
![React](https://img.shields.io/badge/React-19.0.0-blue?style=flat-square&logo=react)
![TypeScript](https://img.shields.io/badge/TypeScript-5.8.2-blue?style=flat-square&logo=typescript)
![Tailwind CSS](https://img.shields.io/badge/Tailwind-3.4.17-06B6D4?style=flat-square&logo=tailwindcss)
![License](https://img.shields.io/badge/License-MIT-green?style=flat-square)

## 🌟 Features

### Core Functionality

- **📜 Script Management**: Browse, search, and filter 300+ Proxmox VE scripts
- **📱 Responsive Design**: Mobile-first approach with modern UI/UX
- **🔍 Advanced Search**: Fuzzy search with category filtering
- **📊 Analytics Integration**: Built-in analytics for usage tracking
- **🌙 Dark/Light Mode**: Theme switching with system preference detection
- **⚡ Performance Optimized**: Static site generation for lightning-fast loading

### Technical Features

- **🎨 Modern UI Components**: Built with Radix UI and shadcn/ui
- **📈 Data Visualization**: Charts and metrics using Chart.js
- **🔄 State Management**: React Query for efficient data fetching
- **📝 Type Safety**: Full TypeScript implementation
- **🚀 Static Export**: Optimized for GitHub Pages deployment

## 🛠️ Tech Stack

### Frontend Framework

- **[Next.js 15.2.4](https://nextjs.org/)** - React framework with App Router
- **[React 19.0.0](https://react.dev/)** - Latest React with concurrent features
- **[TypeScript 5.8.2](https://www.typescriptlang.org/)** - Type-safe JavaScript

### Styling & UI

- **[Tailwind CSS 3.4.17](https://tailwindcss.com/)** - Utility-first CSS framework
- **[Radix UI](https://www.radix-ui.com/)** - Unstyled, accessible UI components
- **[shadcn/ui](https://ui.shadcn.com/)** - Re-usable components built on Radix UI
- **[Framer Motion](https://www.framer.com/motion/)** - Animation library
- **[Lucide React](https://lucide.dev/)** - Icon library

### Data & State Management

- **[TanStack Query 5.71.1](https://tanstack.com/query)** - Powerful data synchronization
- **[Zod 3.24.2](https://zod.dev/)** - TypeScript-first schema validation
- **[nuqs 2.4.1](https://nuqs.47ng.com/)** - Type-safe search params state manager

### Development Tools

- **[Vitest 3.1.1](https://vitest.dev/)** - Fast unit testing framework
- **[React Testing Library](https://testing-library.com/react)** - Simple testing utilities
- **[ESLint](https://eslint.org/)** - Code linting and formatting
- **[Prettier](https://prettier.io/)** - Code formatting

### Additional Libraries

- **[Chart.js](https://www.chartjs.org/)** - Data visualization
- **[Fuse.js](https://fusejs.io/)** - Fuzzy search
- **[date-fns](https://date-fns.org/)** - Date utility library
- **[Next Themes](https://github.com/pacocoursey/next-themes)** - Theme management

## 🚀 Getting Started

### Prerequisites

- **Node.js 18+** (recommend using the latest LTS version)
- **npm**, **yarn**, **pnpm**, or **bun** package manager
- **Git** for version control

### Installation

1. **Clone the repository**

   ```bash
   git clone https://github.com/community-scripts/ProxmoxVE.git
   cd ProxmoxVE/frontend
   ```

2. **Install dependencies**

   ```bash
   # Using npm
   npm install

   # Using yarn
   yarn install

   # Using pnpm
   pnpm install

   # Using bun
   bun install
   ```

3. **Start the development server**

   ```bash
   npm run dev
   # or
   yarn dev
   # or
   pnpm dev
   # or
   bun dev
   ```

4. **Open your browser**

   Navigate to [http://localhost:3000](http://localhost:3000) to see the application running.

### Environment Configuration

The application uses the following environment variables:

- `BASE_PATH`: Set to "ProxmoxVE" for GitHub Pages deployment
- Analytics configuration is handled in `src/config/siteConfig.tsx`

## 🧪 Development

### Available Scripts

```bash
# Development
npm run dev          # Start development server with Turbopack
npm run build        # Build for production
npm run start        # Start production server (after build)

# Code Quality
npm run lint         # Run ESLint
npm run typecheck    # Run TypeScript type checking
npm run format:write # Format code with Prettier
npm run format:check # Check code formatting

# Deployment
npm run deploy       # Build and deploy to GitHub Pages
```

### Development Workflow

1. **Feature Development**

   - Create a new branch for your feature
   - Follow the established TypeScript and React patterns
   - Use the existing component library (shadcn/ui)
   - Ensure responsive design principles

2. **Code Standards**

   - Follow TypeScript strict mode
   - Use functional components with hooks
   - Implement proper error boundaries
   - Write descriptive variable and function names
   - Use early returns for better readability

3. **Styling Guidelines**

   - Use Tailwind CSS utility classes
   - Follow mobile-first responsive design
   - Implement dark/light mode considerations
   - Use CSS variables from the design system

4. **Testing**
   - Write unit tests for utility functions
   - Test React components with React Testing Library
   - Ensure accessibility standards are met
   - Run tests before committing

### Component Development

The project uses a component-driven development approach:

```typescript
// Example component structure
import { cn } from "@/lib/utils";
import { Button } from "@/components/ui/button";

interface ComponentProps {
  title: string;
  className?: string;
}

export const Component = ({ title, className }: ComponentProps) => {
  return (
    <div className={cn("default-classes", className)}>
      <Button>{title}</Button>
    </div>
  );
};
```

### Configuration for Static Export

The application is configured for static export in `next.config.mjs`:

```javascript
const nextConfig = {
  output: "export",
  basePath: `/ProxmoxVE`,
  images: {
    unoptimized: true // Required for static export
  }
};
```

## 🤝 Contributing

We welcome contributions from the community! Here's how you can help:

### Getting Started

1. **Fork the repository** on GitHub
2. **Clone your fork** locally
3. **Create a new branch** for your feature or bugfix
4. **Make your changes** following our coding standards
5. **Submit a pull request** with a clear description

### Contribution Guidelines

#### Code Style

- Follow the existing TypeScript and React patterns
- Use descriptive variable and function names
- Implement proper error handling
- Write self-documenting code with appropriate comments

#### Component Guidelines

- Use functional components with hooks
- Implement proper TypeScript types
- Follow accessibility best practices
- Ensure responsive design
- Use the existing design system components

#### Pull Request Process

1. Update documentation if needed
2. Update the README if you've added new features
3. Request review from maintainers

### Areas for Contribution

- **🐛 Bug fixes**: Report and fix issues
- **✨ New features**: Enhance functionality
- **📚 Documentation**: Improve guides and examples
- **🎨 UI/UX**: Improve design and user experience
- **♿ Accessibility**: Enhance accessibility features
- **🚀 Performance**: Optimize loading and runtime performance

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 🙏 Acknowledgments

- **[tteck](https://github.com/tteck)** - Original creator of the Proxmox VE Helper-Scripts
- **[Community-Scripts Organization](https://github.com/community-scripts)** - Maintaining and expanding the project
- **[Proxmox Community](https://forum.proxmox.com/)** - For continuous feedback and support
- **All Contributors** - Thank you for your valuable contributions!

## 📚 Additional Resources

- **[Proxmox VE Documentation](https://pve.proxmox.com/pve-docs/)**
- **[Community Scripts Repository](https://github.com/community-scripts/ProxmoxVE)**
- **[Discord Community](https://discord.gg/3AnUqsXnmK)**
- **[GitHub Discussions](https://github.com/community-scripts/ProxmoxVE/discussions)**

## 🔗 Links

- **🌐 Live Website**: [https://community-scripts.github.io/ProxmoxVE/](https://community-scripts.github.io/ProxmoxVE/)
- **💬 Discord Server**: [https://discord.gg/3AnUqsXnmK](https://discord.gg/3AnUqsXnmK)
- **📝 Change Log**: [https://github.com/community-scripts/ProxmoxVE/blob/main/CHANGELOG.md](https://github.com/community-scripts/ProxmoxVE/blob/main/CHANGELOG.md)

---

**Made with ❤️ by the Community-Scripts team and contributors**
