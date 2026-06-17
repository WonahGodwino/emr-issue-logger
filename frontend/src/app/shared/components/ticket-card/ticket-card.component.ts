import { Component, Input } from '@angular/core';
@Component({ selector: 'app-ticket-card', template: '<div class="card"><ng-content></ng-content></div>', styles: ['.card{background:white;border-radius:12px;padding:20px;box-shadow:0 2px 8px rgba(0,0,0,.06);margin-bottom:16px}'] })
export class TicketCardComponent { @Input() ticket: any; }
