import { Component, Output, EventEmitter } from '@angular/core';
@Component({ selector: 'app-search', template: '<input [ngModel]="query" (ngModelChange)="onChange($event)" placeholder="Search..." class="search-input" />', styles: ['.search-input{width:100%;padding:10px 16px;border:1px solid #ddd;border-radius:8px;font-size:14px}'] })
export class SearchComponent { query = ''; @Output() search = new EventEmitter<string>(); onChange(val: string) { this.query = val; this.search.emit(val); } }
