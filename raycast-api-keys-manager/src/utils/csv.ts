import { ApiKey } from "./storage";
import { stringify } from "csv-stringify/sync";
import { parse } from "csv-parse/sync";
import fs from "fs";
import { showToast, Toast } from "@raycast/api";
import path from "path";
import os from "os";

export async function exportToCsv(keys: ApiKey[]) {
  if (keys.length === 0) {
    await showToast({ style: Toast.Style.Failure, title: "No keys to export" });
    return;
  }

  try {
    const csvData = stringify(
      keys.map((k) => ({
        Name: k.name,
        Key: k.key,
      })),
      {
        header: true,
        columns: ["Name", "Key"],
      }
    );

    const downloadsDir = path.join(os.homedir(), "Downloads");
    const filePath = path.join(downloadsDir, `api-keys-export-${Date.now()}.csv`);
    
    await fs.promises.writeFile(filePath, csvData, "utf-8");
    
    await showToast({ 
      style: Toast.Style.Success, 
      title: "Exported successfully!", 
      message: `Saved to Downloads/api-keys-export-${Date.now()}.csv`
    });
  } catch (error) {
    console.error("Export failed:", error);
    await showToast({ style: Toast.Style.Failure, title: "Export failed" });
  }
}

export async function importFromCsv(filePath: string): Promise<ApiKey[]> {
  try {
    const fileContent = await fs.promises.readFile(filePath, "utf-8");
    
    const records = parse(fileContent, {
      columns: true,
      skip_empty_lines: true,
      trim: true,
    });

    const importedKeys: ApiKey[] = [];
    
    for (const record of records) {
      if (record.Name && record.Key) {
        importedKeys.push({
          id: Math.random().toString(36).substring(2, 9),
          name: record.Name,
          key: record.Key,
          createdAt: Date.now(),
        });
      }
    }

    return importedKeys;
  } catch (error) {
    console.error("Import failed:", error);
    throw new Error("Failed to parse CSV file");
  }
}
