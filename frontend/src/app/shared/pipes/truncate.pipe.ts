import { Pipe, PipeTransform } from '@angular/core';

@Pipe({ name: 'truncate' })
export class TruncatePipe implements PipeTransform {
  transform(value: string, limit: number = 100, completeWords: boolean = false): string {
    if (!value || value.length <= limit) return value;
    let truncated = value.substring(0, limit);
    if (completeWords) {
      const lastSpace = truncated.lastIndexOf(' ');
      if (lastSpace > 0) truncated = truncated.substring(0, lastSpace);
    }
    return truncated + '...';
  }
}
