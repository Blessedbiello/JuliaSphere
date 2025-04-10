export class Logger {
  private context: string;

  constructor(context: string) {
    this.context = context;
  }

  info(message: string): void {
    console.log(`[${this.context}] INFO: ${message}`);
  }

  error(message: string): void {
    console.error(`[${this.context}] ERROR: ${message}`);
  }

  warn(message: string): void {
    console.warn(`[${this.context}] WARN: ${message}`);
  }

  debug(message: string): void {
    console.debug(`[${this.context}] DEBUG: ${message}`);
  }
}
