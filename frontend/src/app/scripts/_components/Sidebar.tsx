"use client";

import type { Category, Script } from "@/lib/types";
import ScriptAccordion from "./ScriptAccordion";

const Sidebar = ({
	items,
	selectedScript,
	setSelectedScript,
}: {
	items: Category[];
	selectedScript: string | null;
	setSelectedScript: (script: string | null) => void;
}) => {
	const uniqueScripts = items.reduce((acc, category) => {
		for (const script of category.scripts) {
			if (!acc.some((s) => s.name === script.name)) {
				acc.push(script);
			}
		}
		return acc;
	}, [] as Script[]);

	return (
		<div className="flex min-w-72 flex-col sm:max-w-72">
			<div className="flex items-end justify-between pb-4">
				<h1 className="text-xl font-bold">Categories</h1>
				<p className="text-xs italic text-muted-foreground">
					{uniqueScripts.length} Total scripts
				</p>
			</div>
			<div className="rounded-lg">
				<ScriptAccordion
					items={items}
					selectedScript={selectedScript}
					setSelectedScript={setSelectedScript}
				/>
			</div>
		</div>
	);
};

export default Sidebar;