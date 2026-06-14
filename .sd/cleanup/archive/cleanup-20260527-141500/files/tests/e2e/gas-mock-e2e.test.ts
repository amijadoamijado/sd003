// tests/e2e/gas-mock-e2e.test.ts

import { LocalEnv } from '../../src/env/LocalEnv';
import { IEnv } from '../../src/interfaces/IEnv';
import { mockSpreadsheetApp, DriveApp, GmailApp, MockPropertiesService, MockLogger, MockUrlFetchApp } from '../../src/mocks';

// Simulate a simple GAS application logic
class GasAppLogic {
  constructor(private env: IEnv, private gmailApp = GmailApp) {}

  runWorkflow(data: string[][], recipient: string, subject: string, body: string): string {
    // 1. Log start
    this.env.getLogger().log('Starting GasAppLogic workflow...');

    // 2. Get or create a spreadsheet
    const ssName = this.env.getPropertiesService().getScriptProperties().getProperty('spreadsheetName') || 'DefaultAppSpreadsheet';
    const activeSpreadsheet = this.env.getSpreadsheetService().getActiveSpreadsheet();
    let ss = activeSpreadsheet.getSheetByName(ssName) ? this.env.getSpreadsheetService().openById(activeSpreadsheet.getId()) : this.env.getSpreadsheetService().create(ssName);
    const sheet = ss.getActiveSheet();

    // 3. Append data to the spreadsheet
    data.forEach(row => sheet.appendRow(row));
    this.env.getLogger().log(`Appended ${data.length} rows to ${ss.getName()}/${sheet.getName()}`);

    // 4. Store a property
    this.env.getPropertiesService().getScriptProperties().setProperty('lastRunDate', new Date().toISOString());

    // 5. Fetch some external data (mocked)
    const externalApiUrl = this.env.getPropertiesService().getScriptProperties().getProperty('externalApiUrl') || 'http://mockapi.com/data';
    const apiResponse = this.env.getHttpClient().fetch(externalApiUrl);
    this.env.getLogger().log(`Fetched external data: ${apiResponse.getContentText()}`);

    // 6. Create a file in Drive
    const fileName = `report_${this.env.getUtilities().formatDate(new Date(), 'UTC', 'yyyyMMdd')}.txt`;
    const fileContent = `Report for ${ss.getName()}:\n${JSON.stringify(sheet.getRange(1, 1, sheet.getLastRow(), sheet.getLastColumn()).getValues())}\nExternal Data: ${apiResponse.getContentText()}`;
    const driveFile = this.env.getDriveService().createFile(fileName, fileContent);
    this.env.getLogger().log(`Created Drive file: ${driveFile.getName()} (ID: ${driveFile.getId()})`);

    // 7. Send an email
    this.gmailApp.sendEmail(recipient, subject, body);
    this.env.getLogger().log(`Sent email to ${recipient}`);

    // 8. Log end
    this.env.getLogger().log('GasAppLogic workflow completed.');

    return driveFile.getId();
  }
}

describe('GAS Mock E2E Test', () => {
  let localEnv: LocalEnv;
  let appLogic: GasAppLogic;

  beforeEach(() => {
    localEnv = new LocalEnv();
    appLogic = new GasAppLogic(localEnv);

    // Reset all mock services
    mockSpreadsheetApp.reset();
    DriveApp.reset();
    GmailApp.reset();
    MockPropertiesService.reset();
    MockLogger.reset();
    MockUrlFetchApp.reset();

    // Ensure active spreadsheet has a default sheet after reset
    mockSpreadsheetApp.getActiveSpreadsheet().insertSheet('Sheet1');

    // Set up initial mock data
    MockPropertiesService.getScriptProperties().setProperty('spreadsheetName', 'MyTestSpreadsheet');
    MockPropertiesService.getScriptProperties().setProperty('externalApiUrl', 'http://mockapi.com/external');
    MockUrlFetchApp.setMockResponse('http://mockapi.com/external', '{"status": "ok", "data": [1,2,3]}');
  });

  afterEach(() => {
    jest.restoreAllMocks();
  });

  it('should execute a full GAS application workflow successfully in the mock environment', () => {
    const testData = [['Name', 'Value'], ['Item A', '100'], ['Item B', '200']];
    const recipient = 'user@example.com';
    const subject = 'Workflow Report';
    const body = 'Please find the attached report.';

    const createdFileId = appLogic.runWorkflow(testData, recipient, subject, body);

    // Verify Logger output
    const logs = MockLogger.getLogs();
    expect(logs).toEqual(
      expect.arrayContaining([
        expect.objectContaining({ message: expect.stringContaining('Starting GasAppLogic workflow...') }),
      ])
    );
    expect(logs).toEqual(
      expect.arrayContaining([
        expect.objectContaining({ message: expect.stringContaining('Appended 3 rows to MyTestSpreadsheet/Sheet1') }),
      ])
    );
    expect(logs).toEqual(
      expect.arrayContaining([
        expect.objectContaining({ message: expect.stringContaining('Fetched external data: {"status": "ok", "data": [1,2,3]}') }),
      ])
    );
    expect(logs.some(log => /Created Drive file: report_.+\.txt \(ID: file-\d+\)/.test(log.message))).toBe(true);
    expect(logs).toEqual(
      expect.arrayContaining([
        expect.objectContaining({ message: expect.stringContaining(`Sent email to ${recipient}`) }),
      ])
    );
    expect(logs).toEqual(
      expect.arrayContaining([
        expect.objectContaining({ message: expect.stringContaining('GasAppLogic workflow completed.') }),
      ])
    );

    // Verify PropertiesService
    expect(localEnv.getPropertiesService().getScriptProperties().getProperty('lastRunDate')).toBeDefined();
    expect(localEnv.getPropertiesService().getScriptProperties().getProperty('lastRunDate')).toMatch(/^\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}\.\d{3}Z$/);

    // Verify UrlFetchApp
    expect(MockUrlFetchApp.fetch('http://mockapi.com/external').getContentText()).toBe('{"status": "ok", "data": [1,2,3]}');

    // Verify DriveApp
    const driveFile = localEnv.getDriveService().getFileById(createdFileId);
    expect(driveFile.getName()).toMatch(/^report_.+\.txt$/);
    const fileContent = driveFile.getBlob().getDataAsString();
    expect(fileContent).toContain('Report for MyTestSpreadsheet:');
    expect(fileContent).toContain('[["Name","Value"],["Item A","100"],["Item B","200"]]');
    expect(fileContent).toContain('External Data: {"status": "ok", "data": [1,2,3]}');

    // Verify GmailApp
    const sentEmails = GmailApp.getSentEmails();
    expect(sentEmails.length).toBe(1);
    expect(sentEmails[0].to).toBe(recipient);
    expect(sentEmails[0].subject).toBe(subject);
    expect(sentEmails[0].body).toBe(body);
  });
});
