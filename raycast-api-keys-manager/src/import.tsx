import { Form, ActionPanel, Action, useNavigation, showToast, Toast } from "@raycast/api";
import { useState } from "react";
import fs from "fs";
import { getApiKeys, setApiKeys } from "./utils/storage";
import { importFromCsv } from "./utils/csv";

interface ImportFormProps {
  onImported: () => void;
}

export default function ImportForm({ onImported }: ImportFormProps) {
  const [fileError, setFileError] = useState<string | undefined>();
  const { pop } = useNavigation();

  async function handleSubmit(values: { files: string[] }) {
    const files = values.files;
    
    if (!files || files.length === 0) {
      setFileError("Please select a CSV file");
      return;
    }

    const filePath = files[0];
    
    if (!fs.existsSync(filePath) || !fs.lstatSync(filePath).isFile()) {
      setFileError("Invalid file selected");
      return;
    }

    if (!filePath.toLowerCase().endsWith('.csv')) {
      setFileError("Please select a valid CSV file");
      return;
    }

    try {
      const importedKeys = await importFromCsv(filePath);
      
      if (importedKeys.length === 0) {
        await showToast({ style: Toast.Style.Failure, title: "No valid keys found in CSV" });
        return;
      }

      const existingKeys = await getApiKeys();
      
      // Basic merge - we append all imported keys
      await setApiKeys([...existingKeys, ...importedKeys]);

      await showToast({ 
        style: Toast.Style.Success, 
        title: `Imported ${importedKeys.length} key(s) successfully!` 
      });
      
      onImported();
      pop();
    } catch (error) {
      console.error(error);
      await showToast({ style: Toast.Style.Failure, title: "Failed to import CSV" });
    }
  }

  return (
    <Form
      actions={
        <ActionPanel>
          <Action.SubmitForm title="Import CSV" onSubmit={handleSubmit} />
        </ActionPanel>
      }
    >
      <Form.Description text="Select a CSV file containing your API keys. The CSV must have 'Name' and 'Key' columns." />
      <Form.FilePicker 
        id="files" 
        title="Select CSV File"
        allowMultipleSelection={false} 
        error={fileError}
        onChange={() => setFileError(undefined)}
      />
    </Form>
  );
}
