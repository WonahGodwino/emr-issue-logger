import { Injectable } from '@angular/core';
import { HttpInterceptor, HttpRequest, HttpHandler, HttpEvent, HttpErrorResponse } from '@angular/common/http';
import { Observable, throwError } from 'rxjs';
import { catchError } from 'rxjs/operators';
import { Router } from '@angular/router';
import { ToastService } from '../services/toast.service';

@Injectable()
export class ErrorInterceptor implements HttpInterceptor {
  constructor(private router: Router, private toastService: ToastService) {}
  intercept(request: HttpRequest<any>, next: HttpHandler): Observable<HttpEvent<any>> {
    return next.handle(request).pipe(
      catchError((error: HttpErrorResponse) => {
        let errorMessage = 'An error occurred';
        if (error.error?.error) errorMessage = error.error.error;
        else if (error.status === 401) {
          errorMessage = 'Session expired. Please login again.';
          localStorage.clear();
          this.router.navigate(['/login']);
        } else if (error.status === 403) errorMessage = 'You do not have permission.';
        else if (error.status === 404) errorMessage = 'Resource not found.';
        else if (error.status === 500) errorMessage = 'Server error. Please try again.';
        this.toastService.showError(errorMessage);
        return throwError(() => error);
      })
    );
  }
}
