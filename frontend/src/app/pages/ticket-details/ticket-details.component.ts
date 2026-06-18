import { Component, OnInit } from '@angular/core';
import { ActivatedRoute } from '@angular/router';
import { TicketService, Ticket } from '../../core/services/ticket.service';
import { ToastService } from '../../core/services/toast.service';

@Component({
  selector: 'app-ticket-details',
  templateUrl: './ticket-details.component.html',
  styleUrls: ['./ticket-details.component.css']
})
export class TicketDetailsComponent implements OnInit {
  ticket: Ticket | null = null;
  loading = true;

  constructor(
    private route: ActivatedRoute,
    private ticketService: TicketService,
    private toast: ToastService
  ) {}

  ngOnInit(): void {
    const id = this.route.snapshot.paramMap.get('id');
    if (id) {
      this.ticketService.getTicket(id).subscribe({
        next: (t) => { this.ticket = t; this.loading = false; },
        error: () => { this.toast.showError('Ticket not found'); this.loading = false; }
      });
    }
  }

  getStatusColor(s: string): string {
    const c: Record<string,string> = { pending: '#f59e0b', 'under-review': '#3b82f6', 'in-progress': '#8b5cf6', resolved: '#10b981', escalated: '#ef4444' };
    return c[s] || '#6b7280';
  }
  getStatusLabel(s: string): string { return s.replace(/-/g, ' ').replace(/\b\w/g, c => c.toUpperCase()); }
}