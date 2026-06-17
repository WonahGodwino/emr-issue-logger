import { Injectable } from '@angular/core';
import { HttpClient, HttpParams } from '@angular/common/http';
import { Observable } from 'rxjs';
import { environment } from '../../../environments/environment';

export interface Ticket {
  id: string; ticketId: string; title: string; description: string;
  reporterUserId: string; category: string; orderOfImpact: number;
  isNewRequirement: boolean; status: string; statusHistory: any[];
  assignedTo?: string; resolutionNotes?: string; createdAt: string;
  updatedAt: string; resolvedAt?: string; isRecalled: boolean;
  recalledAt?: string; recallReason?: string;
}

export interface CreateTicketRequest {
  title: string; description: string; category: string;
  orderOfImpact: number; isNewRequirement: boolean;
}

export interface TicketFilter {
  status?: string[]; category?: string[]; reporter?: string;
  sort?: string; page?: number; limit?: number;
}

@Injectable({ providedIn: 'root' })
export class TicketService {
  constructor(private http: HttpClient) {}

  createTicket(data: CreateTicketRequest): Observable<Ticket> {
    return this.http.post<Ticket>(`${environment.apiUrl}/tickets`, data);
  }

  getTickets(filter?: TicketFilter): Observable<any> {
    let params = new HttpParams();
    if (filter) {
      if (filter.status) filter.status.forEach(s => params = params.append('status', s));
      if (filter.category) filter.category.forEach(c => params = params.append('category', c));
      if (filter.reporter) params = params.set('reporter', filter.reporter);
      if (filter.sort) params = params.set('sort', filter.sort);
      if (filter.page) params = params.set('page', filter.page.toString());
      if (filter.limit) params = params.set('limit', filter.limit.toString());
    }
    return this.http.get(`${environment.apiUrl}/tickets`, { params });
  }

  getTicket(id: string): Observable<Ticket> {
    return this.http.get<Ticket>(`${environment.apiUrl}/tickets/${id}`);
  }

  updateTicket(id: string, data: any): Observable<Ticket> {
    return this.http.put<Ticket>(`${environment.apiUrl}/tickets/${id}`, data);
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