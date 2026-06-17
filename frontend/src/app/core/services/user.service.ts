import { Injectable } from '@angular/core';
import { HttpClient } from '@angular/common/http';
import { Observable } from 'rxjs';
import { environment } from '../../../environments/environment';
import { User } from './auth.service';

@Injectable({ providedIn: 'root' })
export class UserService {
  constructor(private http: HttpClient) {}
  getCurrentUser(): Observable<User> {
    return this.http.get<User>(`${environment.apiUrl}/users/me`);
  }
  updateProfile(data: { fullName?: string; username?: string }): Observable<any> {
    return this.http.put(`${environment.apiUrl}/users/me`, data);
  }
  getAllUsers(): Observable<User[]> {
    return this.http.get<User[]>(`${environment.apiUrl}/admin/users`);
  }
}