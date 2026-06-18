import { Component, OnInit } from '@angular/core';
import { TicketService, Ticket, UpdateStatusRequest } from '../../core/services/ticket.service';
import { ToastService } from '../../core/services/toast.service';

@Component({
  selector: 'app-my-tickets',
  templateUrl: './my-tickets.component.html',
  styleUrls: ['./my-tickets.component.css']
})
export class MyTicketsComponent implements OnInit {
  tickets: Ticket[] = [];
  loading = false;
  selectedTicket: Ticket | null = null;
  screenshotFile: File | null = null;
  uploading = false;

  constructor(private ticketService: TicketService, private toast: ToastService) {}

  ngOnInit(): void { this.loadTickets(); }

  loadTickets(): void {
    this.loading = true;
    this.ticketService.getTickets().subscribe({
      next: (res) => { this.tickets = res.tickets; this.loading = false; },
      error: () => { this.toast.showError('Failed to load tickets'); this.loading = false; }
    });
  }

  deleteTicket(ticket: Ticket): void {
    if (!confirm(`Delete ticket "${ticket.title}"?`)) return;
    this.ticketService.deleteTicket(ticket.ticketId).subscribe({
      next: () => { this.toast.showSuccess('Ticket deleted'); this.loadTickets(); },
      error: (err) => this.toast.showError(err?.error?.error || 'Failed to delete')
    });
  }

  openScreenshotUpload(ticket: Ticket): void { this.selectedTicket = ticket; }
  closeModal(): void { this.selectedTicket = null; this.screenshotFile = null; }

  onFileSelected(event: Event): void {
    const input = event.target as HTMLInputElement;
    if (input.files?.length) this.screenshotFile = input.files[0];
  }

  uploadScreenshot(): void {
    const ticket = this.selectedTicket;
    const file = this.screenshotFile;
    if (!ticket || !file) { this.toast.showError('Select a file'); return; }
    this.uploading = true;
    this.ticketService.uploadScreenshot(ticket.ticketId, file).subscribe({
      next: (res) => {
        this.uploading = false;
        this.toast.showSuccess('Screenshot uploaded');
        if (this.selectedTicket) this.selectedTicket.screenshots = res.ticket.screenshots;
        this.loadTickets();
      },
      error: (err) => { this.uploading = false; this.toast.showError(err?.error?.error || 'Upload failed'); }
    });
  }

  getStatusColor(s: string): string {
    const c: Record<string,string> = { pending: '#f59e0b', 'under-review': '#3b82f6', 'in-progress': '#8b5cf6', resolved: '#10b981', escalated: '#ef4444' };
    return c[s] || '#6b7280';
  }
  getStatusLabel(s: string): string { return s.replace(/-/g, ' ').replace(/\b\w/g, c => c.toUpperCase()); }

  onOverlayClick(e: MouseEvent): void { if ((e.target as HTMLElement).classList.contains('modal-overlay')) this.closeModal(); }
}