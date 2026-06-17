import { Component, Input } from '@angular/core';
@Component({ selector: 'app-status-badge', template: '<span class="badge" [ngClass]="status"><ng-content></ng-content></span>', styles: ['.badge{display:inline-block;padding:4px 12px;border-radius:20px;font-size:12px;font-weight:600}.pending{background:#fff3cd;color:#856404}.in-progress{background:#cce5ff;color:#004085}.resolved{background:#d4edda;color:#155724}'] })
export class StatusBadgeComponent { @Input() status = 'pending'; }
