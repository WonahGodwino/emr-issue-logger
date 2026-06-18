import { Component, OnInit } from '@angular/core';
import { TicketService } from '../../core/services/ticket.service';
import { ToastService } from '../../core/services/toast.service';

@Component({
  selector: 'app-admin-dashboard',
  templateUrl: './admin-dashboard.component.html',
  styleUrls: ['./admin-dashboard.component.css']
})
export class AdminDashboardComponent implements OnInit {
  stats: any = { totalTickets: 0, pendingTickets: 0, inProgressTickets: 0, resolvedTickets: 0, totalUsers: 0, recalledTickets: 0 };
  loading = true;

  constructor(private ticketService: TicketService, private toast: ToastService) {}

  ngOnInit(): void {
    this.ticketService.getDashboardStats().subscribe({
      next: (s) => { this.stats = s; this.loading = false; },
      error: () => { this.toast.showError('Failed to load stats'); this.loading = false; }
    });
  }
}