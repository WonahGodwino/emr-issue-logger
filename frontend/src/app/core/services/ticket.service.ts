import { Injectable } from '@angular/core';
import { HttpClient, HttpParams } from '@angular/common/http';
import { Observable } from 'rxjs';
import { environment } from '../../../environments/environment';

export interface Ticket {
  id: string; ticketId: string; title: string; description: string;
  issue: string; module: string; reporterUserId: string;
  facilityId: string; stateId: string;
  category: string; orderOfImpact: number;
  isNewRequirement: boolean; status: string; statusHistory: any[];
  assignedTo?: string; resolutionNotes?: string;
  escalationComment?: string; screenshots?: string[];
  createdAt: string; createdBy: string;
  updatedAt: string; updatedBy: string;
  adminUpdatedAt?: string; updatedByAdmin?: string;
  resolvedAt?: string; isRecalled: boolean;
  recalledAt?: string; recallReason?: string;
}

export interface CreateTicketRequest {
  title: string; description: string; issue: string;
  module: string; facilityId: string;
  category: string; orderOfImpact: number; isNewRequirement: boolean;
}

export interface UpdateStatusRequest {
  status: string; resolutionNotes?: string; escalationComment?: string;
}

@Injectable({ providedIn: 'root' })
export class TicketService {
  constructor(private http: HttpClient) {}

  createTicket(data: CreateTicketRequest): Observable<Ticket> {
    return this.http.post<Ticket>(`${environment.apiUrl}/tickets`, data);
  }

  getTickets(filters?: { dateFrom?: string; dateTo?: string; status?: string; stateId?: string; facilityId?: string }): Observable<{ tickets: Ticket[]; count: number }> {
    let params = new HttpParams();
    if (filters) {
      if (filters.dateFrom) params = params.set('dateFrom', filters.dateFrom);
      if (filters.dateTo) params = params.set('dateTo', filters.dateTo);
      if (filters.status) params = params.set('status', filters.status);
      if (filters.stateId) params = params.set('stateId', filters.stateId);
      if (filters.facilityId) params = params.set('facilityId', filters.facilityId);
    }
    return this.http.get<{ tickets: Ticket[]; count: number }>(`${environment.apiUrl}/tickets`, { params });
  }

  getTicket(id: string): Observable<Ticket> {
    return this.http.get<Ticket>(`${environment.apiUrl}/tickets/${id}`);
  }

  updateTicket(id: string, data: any): Observable<Ticket> {
    return this.http.put<Ticket>(`${environment.apiUrl}/tickets/${id}`, data);
  }

  updateTicketStatus(id: string, data: UpdateStatusRequest): Observable<Ticket> {
    return this.http.post<Ticket>(`${environment.apiUrl}/tickets/${id}/status`, data);
  }

  uploadScreenshot(id: string, file: File): Observable<{ screenshotUrl: string; ticket: Ticket }> {
    const formData = new FormData();
    formData.append('screenshot', file);
    return this.http.post<{ screenshotUrl: string; ticket: Ticket }>(`${environment.apiUrl}/tickets/${id}/screenshots`, formData);
  }

  deleteTicket(id: string): Observable<any> {
    return this.http.delete(`${environment.apiUrl}/tickets/${id}`);
  }

  recallTicket(id: string, reason: string): Observable<any> {
    return this.http.post(`${environment.apiUrl}/tickets/${id}/recall`, { reason });
  }

  getDashboardStats(): Observable<any> {
    return this.http.get(`${environment.apiUrl}/admin/dashboard`);
  }
}

@Injectable({ providedIn: 'root' })
export class AdminService {
  constructor(private http: HttpClient) {}

  getUsers(): Observable<any[]> {
    return this.http.get<any[]>(`${environment.apiUrl}/admin/users`);
  }

  assignStatesToAdmin(userId: string, stateIds: string[]): Observable<any> {
    return this.http.put(`${environment.apiUrl}/admin/users/${userId}/states`, { stateIds });
  }
}