import { Component, OnInit } from '@angular/core';
import { TicketService, Ticket, UpdateStatusRequest } from '../../core/services/ticket.service';
import { StateService, State } from '../../core/services/state.service';
import { ToastService } from '../../core/services/toast.service';
import { AuthService } from '../../core/services/auth.service';

@Component({
  selector: 'app-manage-tickets',
  templateUrl: './manage-tickets.component.html',
  styleUrls: ['./manage-tickets.component.css']
})
export class ManageTicketsComponent implements OnInit {
  tickets: Ticket[] = [];
  states: State[] = [];
  loading = false;

  // Filters
  filterStatus = '';
  filterStateId = '';
  filterDateFrom = '';
  filterDateTo = '';

  // Status update modal
  selectedTicket: Ticket | null = null;
  statusForm: UpdateStatusRequest = { status: 'under-review', resolutionNotes: '', escalationComment: '' };
  statusUpdating = false;

  // Screenshot
  screenshotFile: File | null = null;
  screenshotUploading = false;

  isSuperAdmin = false;

  statusOptions = [
    { value: 'under-review', label: 'Under Review', color: '#f59e0b' },
    { value: 'in-progress', label: 'In Progress', color: '#3b82f6' },
    { value: 'resolved', label: 'Resolved', color: '#10b981' },
    { value: 'escalated', label: 'Escalated', color: '#ef4444' },
  ];

  constructor(
    private ticketService: TicketService,
    private stateService: StateService,
    private toast: ToastService,
    private authService: AuthService
  ) {}

  ngOnInit(): void {
    this.isSuperAdmin = this.authService.isSuperAdmin();
    this.stateService.getStates().subscribe({
      next: (data) => this.states = data,
      error: () => this.toast.showError('Failed to load states')
    });
    this.loadTickets();
  }

  loadTickets(): void {
    this.loading = true;
    const filters: any = {};
    if (this.filterStatus) filters.status = this.filterStatus;
    if (this.filterStateId) filters.stateId = this.filterStateId;
    if (this.filterDateFrom) filters.dateFrom = this.filterDateFrom;
    if (this.filterDateTo) filters.dateTo = this.filterDateTo;

    this.ticketService.getTickets(filters).subscribe({
      next: (res) => { this.tickets = res.tickets; this.loading = false; },
      error: () => { this.toast.showError('Failed to load tickets'); this.loading = false; }
    });
  }

  applyFilters(): void {
    this.loadTickets();
  }

  clearFilters(): void {
    this.filterStatus = '';
    this.filterStateId = '';
    this.filterDateFrom = '';
    this.filterDateTo = '';
    this.loadTickets();
  }

  openStatusUpdate(ticket: Ticket): void {
    this.selectedTicket = ticket;
    this.statusForm = {
      status: ticket.status === 'pending' ? 'under-review' : ticket.status,
      resolutionNotes: '',
      escalationComment: ''
    };
  }

  closeStatusModal(): void {
    this.selectedTicket = null;
    this.screenshotFile = null;
  }

  updateStatus(): void {
    if (!this.selectedTicket) return;
    if (this.statusForm.status === 'escalated' && !this.statusForm.escalationComment.trim()) {
      this.toast.showError('Escalation requires a comment');
      return;
    }
    this.statusUpdating = true;
    this.ticketService.updateTicketStatus(this.selectedTicket.ticketId, this.statusForm).subscribe({
      next: (updated) => {
        this.statusUpdating = false;
        this.toast.showSuccess('Status updated to ' + this.getStatusLabel(updated.status));
        this.selectedTicket = null;
        this.loadTickets();
      },
      error: (err) => {
        this.statusUpdating = false;
        this.toast.showError(err?.error?.error || 'Failed to update status');
      }
    });
  }

  onScreenshotFileSelected(event: Event): void {
    const input = event.target as HTMLInputElement;
    if (input.files && input.files.length > 0) {
      this.screenshotFile = input.files[0];
    }
  }

  uploadScreenshot(): void {
    const ticket = this.selectedTicket;
    const file = this.screenshotFile;
    if (!ticket || !file) {
      this.toast.showError('Select a screenshot file');
      return;
    }
    this.screenshotUploading = true;
    this.ticketService.uploadScreenshot(ticket.ticketId, file).subscribe({
      next: (res) => {
        this.screenshotUploading = false;
        this.toast.showSuccess('Screenshot uploaded');
        if (this.selectedTicket) {
          this.selectedTicket.screenshots = res.ticket.screenshots;
        }
      },
      error: (err) => {
        this.screenshotUploading = false;
        this.toast.showError(err?.error?.error || 'Failed to upload screenshot');
      }
    });
  }

  getStatusLabel(status: string): string {
    const found = this.statusOptions.find(s => s.value === status);
    return found ? found.label : status;
  }

  getStatusColor(status: string): string {
    const found = this.statusOptions.find(s => s.value === status);
    return found ? found.color : '#6b7280';
  }

  getModuleLabel(module: string): string {
    const mods: Record<string, string> = {
      emr: 'EMR', pharmacy: 'Pharmacy', lab: 'Lab', billing: 'Billing',
      registration: 'Registration', reports: 'Reports', inventory: 'Inventory', other: 'Other'
    };
    return mods[module] || module;
  }

  onOverlayClick(event: MouseEvent): void {
    if ((event.target as HTMLElement).classList.contains('modal-overlay')) {
      this.closeStatusModal();
    }
  }
}