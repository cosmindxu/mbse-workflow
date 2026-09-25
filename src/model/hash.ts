import { createHash } from 'node:crypto';

/** Content hash used to decide what a change invalidates. */
export const sha = (text: string): string => createHash('sha256').update(text, 'utf8').digest('hex').slice(0, 16);
