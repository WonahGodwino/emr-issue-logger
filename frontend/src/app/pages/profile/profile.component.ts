import { Component, OnInit } from '@angular/core';
import { AuthService } from '../../core/services/auth.service';
import { HttpClient } from '@angular/common/http';
import { environment } from '../../../environments/environment';
import { ToastService } from '../../core/services/toast.service';

@Component({
  selector: 'app-profile',
  templateUrl: './profile.component.html',
  styleUrls: ['./profile.component.css']
})
export class ProfileComponent implements OnInit {
  user: any = null;
  form = { fullName: '', username: '', email: '' };
  saving = false;

  constructor(private authService: AuthService, private http: HttpClient, private toast: ToastService) {}

  ngOnInit(): void {
    this.loadProfile();
  }

  loadProfile(): void {
    this.http.get(`${environment.apiUrl}/users/me`).subscribe({
      next: (u: any) => {
        this.user = u;
        this.form = { fullName: u.fullName, username: u.username, email: u.email };
      },
      error: () => this.toast.showError('Failed to load profile')
    });
  }

  save(): void {
    this.saving = true;
    this.http.put(`${environment.apiUrl}/users/me`, this.form).subscribe({
      next: (u: any) => {
        this.user = u;
        this.saving = false;
        this.toast.showSuccess('Profile updated');
      },
      error: (err) => { this.saving = false; this.toast.showError(err?.error?.error || 'Failed to update'); }
    });
  }
}