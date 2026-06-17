import { Component } from '@angular/core';
import { Router, NavigationEnd } from '@angular/router';
import { filter } from 'rxjs/operators';

@Component({
  selector: 'app-root',
  template: `
    <app-navbar *ngIf="isAuthenticated"></app-navbar>
    <app-sidebar *ngIf="isAuthenticated"></app-sidebar>
    <main [class.with-sidebar]="isAuthenticated">
      <router-outlet></router-outlet>
    </main>
    <app-footer *ngIf="isAuthenticated"></app-footer>
    <app-toast></app-toast>
    <app-loader></app-loader>
  `,
  styles: [`
    main {
      min-height: calc(100vh - 64px);
      background: #f5f7fa;
      transition: margin-left 0.3s ease;
      padding: 88px 24px 24px 24px;
    }
    main.with-sidebar {
      margin-left: 250px;
    }
    @media (max-width: 768px) {
      main.with-sidebar {
        margin-left: 0;
        padding: 16px;
      }
    }
  `]
})
export class AppComponent {
  get isAuthenticated(): boolean {
    return !!localStorage.getItem('accessToken');
  }
}