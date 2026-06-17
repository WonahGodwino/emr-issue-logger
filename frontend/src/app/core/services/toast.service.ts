import { Injectable } from '@angular/core';
import { BehaviorSubject } from 'rxjs';

export interface ToastMessage {
  type: 'success' | 'error' | 'warning' | 'info';
  message: string; duration?: number;
}

@Injectable({ providedIn: 'root' })
export class ToastService {
  private toastsSubject = new BehaviorSubject<ToastMessage[]>([]);
  toasts$ = this.toastsSubject.asObservable();
  private toasts: ToastMessage[] = [];

  show(message: string, type: 'success' | 'error' | 'warning' | 'info' = 'info', duration: number = 5000): void {
    const toast: ToastMessage = { message, type, duration };
    this.toasts.push(toast);
    this.toastsSubject.next(this.toasts);
    setTimeout(() => this.remove(toast), duration);
  }

  showSuccess(message: string, duration?: number): void { this.show(message, 'success', duration); }
  showError(message: string, duration?: number): void { this.show(message, 'error', duration); }
  showWarning(message: string, duration?: number): void { this.show(message, 'warning', duration); }
  showInfo(message: string, duration?: number): void { this.show(message, 'info', duration); }

  remove(toast: ToastMessage): void {
    this.toasts = this.toasts.filter(t => t !== toast);
    this.toastsSubject.next(this.toasts);
  }
  clear(): void { this.toasts = []; this.toastsSubject.next(this.toasts); }
}
