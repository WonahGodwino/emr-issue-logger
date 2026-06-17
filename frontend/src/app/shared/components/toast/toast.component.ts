import { Component } from '@angular/core';
import { ToastService, ToastMessage } from '../../../core/services/toast.service';

@Component({
  selector: 'app-toast',
  template: `
    <div class="toast-container">
      <div *ngFor="let toast of toasts$ | async" class="toast" [ngClass]="'toast-' + toast.type" (click)="removeToast(toast)">
        <span class="toast-icon">{{ getIcon(toast.type) }}</span>
        <span class="toast-message">{{ toast.message }}</span>
        <button class="toast-close">&times;</button>
      </div>
    </div>
  `,
  styles: [`
    .toast-container { position: fixed; top: 80px; right: 20px; z-index: 9999; display: flex; flex-direction: column; gap: 10px; max-width: 400px; width: 100%; }
    .toast { display: flex; align-items: center; gap: 12px; padding: 14px 18px; border-radius: 12px; background: white; box-shadow: 0 8px 30px rgba(0,0,0,0.15); cursor: pointer; transition: all 0.3s; border-left: 4px solid #667eea; }
    .toast:hover { transform: translateX(-4px); }
    .toast-success { border-left-color: #28a745; }
    .toast-error { border-left-color: #dc3545; }
    .toast-warning { border-left-color: #ffc107; }
    .toast-info { border-left-color: #667eea; }
    .toast-icon { font-size: 20px; flex-shrink: 0; }
    .toast-message { flex: 1; color: #333; font-size: 14px; font-weight: 500; }
    .toast-close { background: none; border: none; color: #999; cursor: pointer; font-size: 16px; padding: 0 4px; }
    .toast-close:hover { color: #333; }
  `]
})
export class ToastComponent {
  toasts$ = this.toastService.toasts$;
  constructor(private toastService: ToastService) {}
  getIcon(type: string): string {
    const icons: any = { success: '✅', error: '❌', warning: '⚠️' };
    return icons[type] || 'ℹ️';
  }
  removeToast(toast: ToastMessage): void { this.toastService.remove(toast); }
}