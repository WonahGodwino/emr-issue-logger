import { Component, Input } from '@angular/core';
@Component({ selector: 'app-statistics-card', template: '<div class="stat-card"><h3>{{title}}</h3><p class="value">{{value}}</p></div>', styles: ['.stat-card{background:white;border-radius:12px;padding:24px;text-align:center;box-shadow:0 2px 8px rgba(0,0,0,.06)}.value{font-size:32px;font-weight:700;color:#667eea}'] })
export class StatisticsCardComponent { @Input() title = ''; @Input() value: string | number = ''; }
