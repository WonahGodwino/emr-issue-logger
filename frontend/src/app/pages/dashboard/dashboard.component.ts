import { Component, OnInit } from '@angular/core';
import { TicketService, Ticket } from '../../core/services/ticket.service';
import { AuthService } from '../../core/services/auth.service';
import { ToastService } from '../../core/services/toast.service';

@Component({
  selector: 'app-dashboard',
  templateUrl: './dashboard.component.html',
  styleUrls: ['./dashboard.component.css']
})
export class DashboardComponent implements OnInit {
  tickets: Ticket[] = [];
  loading = false;
  userName = '';
  stats = { total: 0, pending: 0, underReview: 0, resolved: 0 };

  constructor(
    private ticketService: TicketService,
    private authService: AuthService,
    private toast: ToastService
  ) {}

  ngOnInit(): void {
    const user = this.authService.getCurrentUser();
    this.userName = user?.fullName || 'User';
    this.loadTickets();
  }

  loadTickets(): void {
    this.loading = true;
    this.ticketService.getTickets().subscribe({
      next: (res) => {
        this.tickets = res.tickets.slice(0, 5);
        this.computeStats(res.tickets);
        this.loading = false;
      },
      error: () => { this.toast.showError('Failed to load tickets'); this.loading = false; }
    });
  }

  computeStats(tickets: Ticket[]): void {
    this.stats.total = tickets.length;
    this.stats.pending = tickets.filter(t => t.status === 'pending').length;
    this.stats.underReview = tickets.filter(t => t.status === 'under-review' || t.status === 'in-progress').length;
    this.stats.resolved = tickets.filter(t => t.status === 'resolved').length;
  }

  getStatusColor(status: string): string {
    const colors: Record<string, string> = {
      pending: '#f59e0b', 'under-review': '#3b82f6', 'in-progress': '#8b5cf6',
      resolved: '#10b981', escalated: '#ef4444'
    };
    return colors[status] || '#6b7280';
  }

  getStatusLabel(status: string): string {
    return status.replace(/-/g, ' ').replace(/\b\w/g, c => c.toUpperCase());
  }
}