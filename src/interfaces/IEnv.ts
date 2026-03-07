/**
 * Environment Interface Pattern - SD003 Framework
 *
 * ビジネスロジックをGAS APIから完全分離するための統一インターフェース
 * GA001依存を排除し、全インターフェースをインライン定義
 *
 * @version 3.0.0
 */

// ============================================================================
// Enums & Helper Types
// ============================================================================

/** Environment type identifier */
export type EnvType = 'gas' | 'local' | 'test';

/** Digest algorithm for hashing */
export enum DigestAlgorithm {
  MD5 = 'MD5',
  SHA_1 = 'SHA_1',
  SHA_256 = 'SHA_256',
  SHA_384 = 'SHA_384',
  SHA_512 = 'SHA_512',
}

/** Generic result type */
export interface IResult<T> {
  success: boolean;
  data?: T;
  error?: string;
}

/** Async result type */
export type IAsyncResult<T> = Promise<IResult<T>>;

/** Environment configuration */
export interface IEnvConfig {
  type: EnvType;
  debug?: boolean;
}

/** Blob-like object */
export interface Blob {
  getBytes(): number[];
  getContentType(): string;
  getName(): string;
  getDataAsString(charset?: string): string;
  setContentType(contentType: string): Blob;
  setName(name: string): Blob;
}

// ============================================================================
// Spreadsheet Service
// ============================================================================

export interface IRange {
  getValue(): any;
  getValues(): any[][];
  setValue(value: any): IRange;
  setValues(values: any[][]): IRange;
  getRow(): number;
  getColumn(): number;
  getNumRows(): number;
  getNumColumns(): number;
  getA1Notation(): string;
  getSheet(): ISheet;
  clear(): IRange;
  clearContent(): IRange;
  setBackground(color: string): IRange;
  setFontWeight(weight: string): IRange;
  setNumberFormat(format: string): IRange;
  merge(): IRange;
  isPartOfMerge(): boolean;
}

export interface ISheet {
  getName(): string;
  getRange(row: number, column: number, numRows?: number, numColumns?: number): IRange;
  getRange(a1Notation: string): IRange;
  getDataRange(): IRange;
  getLastRow(): number;
  getLastColumn(): number;
  getMaxRows(): number;
  getMaxColumns(): number;
  appendRow(rowContents: any[]): ISheet;
  insertRows(rowIndex: number, numRows?: number): void;
  deleteRows(rowIndex: number, numRows?: number): void;
  clear(): ISheet;
  clearContents(): ISheet;
  getSheetId(): number;
  setName(name: string): ISheet;
  activate(): ISheet;
}

export interface ISpreadsheet {
  getActiveSheet(): ISheet;
  getSheetByName(name: string): ISheet | null;
  getSheets(): ISheet[];
  insertSheet(name?: string): ISheet;
  deleteSheet(sheet: ISheet): void;
  getId(): string;
  getName(): string;
  getUrl(): string;
  rename(name: string): void;
}

export interface ISpreadsheetService {
  getActiveSpreadsheet(): ISpreadsheet;
  openById(id: string): ISpreadsheet;
  openByUrl(url: string): ISpreadsheet;
  create(name: string): ISpreadsheet;
}

// ============================================================================
// Logger
// ============================================================================

export interface ILogger {
  log(message: any): void;
  info(message: any): void;
  warn(message: any): void;
  error(message: any): void;
  getLogs(): Array<{ level: string; message: string; timestamp: Date }>;
  clear(): void;
}

// ============================================================================
// Properties Service
// ============================================================================

export interface IProperties {
  getProperty(key: string): string | null;
  setProperty(key: string, value: string): IProperties;
  deleteProperty(key: string): IProperties;
  getProperties(): Record<string, string>;
  setProperties(properties: Record<string, string>, deleteAllOthers?: boolean): IProperties;
  deleteAllProperties(): IProperties;
}

export interface IPropertiesService {
  getScriptProperties(): IProperties;
  getUserProperties(): IProperties;
  getDocumentProperties(): IProperties;
}

// ============================================================================
// HTTP Client (UrlFetchApp)
// ============================================================================

export interface IHttpRequestOptions {
  method?: 'get' | 'post' | 'put' | 'delete' | 'patch';
  headers?: Record<string, string>;
  payload?: string | Record<string, any>;
  contentType?: string;
  muteHttpExceptions?: boolean;
  followRedirects?: boolean;
}

export interface IHttpResponse {
  getResponseCode(): number;
  getContentText(): string;
  getHeaders(): Record<string, string>;
  getBlob(): Blob;
}

export interface IHttpClient {
  fetch(url: string, options?: IHttpRequestOptions): IHttpResponse;
  fetchAll(requests: Array<{ url: string; options?: IHttpRequestOptions }>): IHttpResponse[];
}

// ============================================================================
// Utilities
// ============================================================================

export interface IUtilities {
  formatDate(date: Date, timeZone: string, format: string): string;
  base64Encode(data: string | number[]): string;
  base64Decode(encoded: string): number[];
  computeDigest(algorithm: DigestAlgorithm, value: string): number[];
  newBlob(data: string | number[], contentType?: string, name?: string): Blob;
  sleep(milliseconds: number): void;
  getUuid(): string;
}

// ============================================================================
// Lock Service
// ============================================================================

export interface ILock {
  tryLock(timeoutInMillis: number): boolean;
  releaseLock(): void;
  hasLock(): boolean;
  waitLock(timeoutInMillis: number): void;
}

export interface ILockService {
  getScriptLock(): ILock;
  getUserLock(): ILock;
  getDocumentLock(): ILock;
}

// ============================================================================
// Cache Service
// ============================================================================

export interface ICache {
  get(key: string): string | null;
  put(key: string, value: string, expirationInSeconds?: number): void;
  remove(key: string): void;
  getAll(keys: string[]): Record<string, string>;
  putAll(values: Record<string, string>, expirationInSeconds?: number): void;
  removeAll(keys: string[]): void;
}

export interface ICacheService {
  getScriptCache(): ICache;
  getUserCache(): ICache;
  getDocumentCache(): ICache;
}

// ============================================================================
// Session
// ============================================================================

export interface IUser {
  getEmail(): string;
}

export interface ISession {
  getActiveUser(): IUser;
  getEffectiveUser(): IUser;
  getScriptTimeZone(): string;
  getTemporaryActiveUserKey(): string;
}

// ============================================================================
// HTML Service
// ============================================================================

export interface IHtmlOutput {
  getContent(): string;
  setContent(content: string): IHtmlOutput;
  append(content: string): IHtmlOutput;
  setTitle(title: string): IHtmlOutput;
  setWidth(width: number): IHtmlOutput;
  setHeight(height: number): IHtmlOutput;
  setSandboxMode(mode: any): IHtmlOutput;
  setXFrameOptionsMode(mode: any): IHtmlOutput;
}

export interface IHtmlTemplate {
  evaluate(): IHtmlOutput;
  getRawContent(): string;
}

export interface IHtmlService {
  createHtmlOutput(html?: string): IHtmlOutput;
  createHtmlOutputFromFile(filename: string): IHtmlOutput;
  createTemplate(html: string): IHtmlTemplate;
  createTemplateFromFile(filename: string): IHtmlTemplate;
}

// ============================================================================
// Drive Service
// ============================================================================

export interface IDriveFileIterator {
  hasNext(): boolean;
  next(): IDriveFile;
}

export interface IDriveFolderIterator {
  hasNext(): boolean;
  next(): IDriveFolder;
}

export interface IDriveFile {
  getId(): string;
  getName(): string;
  getUrl(): string;
  getMimeType(): string;
  getSize(): number;
  getDateCreated(): Date;
  getLastUpdated(): Date;
  getBlob(): Blob;
  setName(name: string): IDriveFile;
  setTrashed(trashed: boolean): IDriveFile;
  makeCopy(name?: string, destination?: IDriveFolder): IDriveFile;
  getParents(): IDriveFolderIterator;
  moveTo(destination: IDriveFolder): IDriveFile;
}

export interface IDriveFolder {
  getId(): string;
  getName(): string;
  getUrl(): string;
  createFile(blob: Blob): IDriveFile;
  createFile(name: string, content: string, mimeType?: string): IDriveFile;
  createFolder(name: string): IDriveFolder;
  getFiles(): IDriveFileIterator;
  getFolders(): IDriveFolderIterator;
  getFilesByName(name: string): IDriveFileIterator;
  getFoldersByName(name: string): IDriveFolderIterator;
  setName(name: string): IDriveFolder;
  setTrashed(trashed: boolean): IDriveFolder;
  getParents(): IDriveFolderIterator;
}

export interface IDriveService {
  getFileById(id: string): IDriveFile;
  getFolderById(id: string): IDriveFolder;
  getRootFolder(): IDriveFolder;
  createFile(blob: Blob): IDriveFile;
  createFile(name: string, content: string, mimeType?: string): IDriveFile;
  createFolder(name: string): IDriveFolder;
  getFilesByName(name: string): IDriveFileIterator;
  getFoldersByName(name: string): IDriveFolderIterator;
}

// ============================================================================
// Main Environment Interface
// ============================================================================

/**
 * IEnv: Environment abstraction interface
 *
 * Provides unified access to GAS services regardless of runtime environment.
 * Implement this interface for each target environment (GAS, Local, Test).
 */
export interface IEnv {
  getSpreadsheetService(): ISpreadsheetService;
  getLogger(): ILogger;
  getPropertiesService(): IPropertiesService;
  getHttpClient(): IHttpClient;
  getUtilities(): IUtilities;
  getLockService(): ILockService;
  getCacheService(): ICacheService;
  getSession(): ISession;
  getHtmlService(): IHtmlService;
  getDriveService(): IDriveService;
}
