import type { Metadata } from "next";
import type { ReactNode } from "react";
import "./globals.css";
import { ProgressProvider } from "@/components/progress";
import { SiteShell } from "@/components/site-shell";
import { getCourse, modulesOf } from "@/lib/content";

export const metadata: Metadata = {
  title: { default: "YAML & JSON, from the grammar up", template: "%s · YAML & JSON course" },
  description:
    "A hands-on course in JSON and YAML: grammar, types, jq, anchors, JSON Schema, and the config files you meet at work. Every example was executed and its output captured.",
};

export default function RootLayout({ children }: { children: ReactNode }) {
  const course = getCourse();
  const nav = modulesOf(course).map(({ module, lessons }) => ({
    module,
    lessons: lessons.map((l) => ({ slug: l.slug, title: l.title, number: l.number })),
  }));
  return (
    <html
      lang="en"
      suppressHydrationWarning
    >
      <head>
        <script
          dangerouslySetInnerHTML={{
            __html:
              "try{var t=localStorage.getItem('theme');if(t==='dark'||(!t&&matchMedia('(prefers-color-scheme: dark)').matches))document.documentElement.classList.add('dark')}catch(e){}",
          }}
        />
      </head>
      <body>
        <ProgressProvider>
          <SiteShell nav={nav} lessonCount={course.lessons.length}>
            {children}
          </SiteShell>
        </ProgressProvider>
      </body>
    </html>
  );
}
