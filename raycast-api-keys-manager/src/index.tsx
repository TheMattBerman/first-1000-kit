import { useState, useEffect } from "react";
import { List, ActionPanel, Action, Icon, confirmAlert, Alert } from "@raycast/api";
import { getApiKeys, deleteApiKey, ApiKey } from "./utils/storage";
import AddKeyForm from "./add";
import ImportForm from "./import";
import { exportToCsv } from "./utils/csv";

export default function Command() {
  const [keys, setKeys] = useState<ApiKey[]>([]);
  const [isLoading, setIsLoading] = useState(true);

  useEffect(() => {
    loadKeys();
  }, []);

  async function loadKeys() {
    setIsLoading(true);
    const storedKeys = await getApiKeys();
    setKeys(storedKeys);
    setIsLoading(false);
  }

  async function handleDelete(id: string) {
    if (
      await confirmAlert({
        title: "Delete API Key",
        message: "Are you sure you want to delete this key? This action cannot be undone.",
        primaryAction: {
          title: "Delete",
          style: Alert.ActionStyle.Destructive,
        },
      })
    ) {
      await deleteApiKey(id);
      await loadKeys();
    }
  }

  return (
    <List isLoading={isLoading} searchBarPlaceholder="Search API Keys...">
      <List.EmptyView 
        icon={Icon.Key} 
        title="No API Keys Found" 
        description="Add a new API key manually or import from a CSV file."
        actions={
          <ActionPanel>
             <Action.Push title="Add Key" target={<AddKeyForm onKeyAdded={loadKeys} />} icon={Icon.Plus} />
             <Action.Push title="Import CSV" target={<ImportForm onImported={loadKeys} />} icon={Icon.Upload} />
          </ActionPanel>
        }
      />
      {keys.map((k) => (
        <List.Item
          key={k.id}
          title={k.name}
          icon={Icon.Key}
          accessories={[{ date: new Date(k.createdAt) }]}
          actions={
            <ActionPanel>
              <ActionPanel.Section title="Key Actions">
                <Action.CopyToClipboard title="Copy Key" content={k.key} />
                <Action.Push 
                  title="Edit Key" 
                  target={<AddKeyForm existingKey={k} onKeyAdded={loadKeys} />} 
                  icon={Icon.Pencil} 
                  shortcut={{ modifiers: ["cmd"], key: "e" }}
                />
                <Action 
                  title="Delete Key" 
                  onAction={() => handleDelete(k.id)} 
                  icon={Icon.Trash} 
                  style={Action.Style.Destructive}
                  shortcut={{ modifiers: ["ctrl"], key: "x" }}
                />
              </ActionPanel.Section>
              <ActionPanel.Section title="Global Actions">
                <Action.Push 
                  title="Add New Key" 
                  target={<AddKeyForm onKeyAdded={loadKeys} />} 
                  icon={Icon.Plus} 
                  shortcut={{ modifiers: ["cmd"], key: "n" }}
                />
                <Action 
                  title="Export to CSV" 
                  onAction={() => exportToCsv(keys)} 
                  icon={Icon.Download} 
                  shortcut={{ modifiers: ["cmd"], key: "e" }}
                />
                <Action.Push 
                  title="Import from CSV" 
                  target={<ImportForm onImported={loadKeys} />} 
                  icon={Icon.Upload} 
                  shortcut={{ modifiers: ["cmd"], key: "i" }}
                />
              </ActionPanel.Section>
            </ActionPanel>
          }
        />
      ))}
    </List>
  );
}
