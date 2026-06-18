import { Component, OnInit } from '@angular/core';
import { Router } from '@angular/router';
import { TicketService, CreateTicketRequest } from '../../core/services/ticket.service';
import { StateService, FacilityService, Facility, State } from '../../core/services/state.service';
import { ToastService } from '../../core/services/toast.service';

@Component({
  selector: 'app-create-ticket',
  templateUrl: './create-ticket.component.html',
  styleUrls: ['./create-ticket.component.css']
})
export class CreateTicketComponent implements OnInit {
  form: CreateTicketRequest = {
    title: '',
    description: '',
    issue: '',
    module: 'emr',
    facilityId: '',
    category: 'system-issue',
    orderOfImpact: 1,
    isNewRequirement: false
  };

  states: State[] = [];
  facilities: Facility[] = [];
  selectedStateId = '';
  loading = false;

  modules = [
    { value: 'emr', label: 'EMR' },
    { value: 'pharmacy', label: 'Pharmacy' },
    { value: 'lab', label: 'Lab' },
    { value: 'billing', label: 'Billing' },
    { value: 'registration', label: 'Registration' },
    { value: 'reports', label: 'Reports' },
    { value: 'inventory', label: 'Inventory' },
    { value: 'other', label: 'Other' }
  ];

  categories = [
    { value: 'system-issue', label: 'System Issue' },
    { value: 'data-integrity', label: 'Data Integrity' },
    { value: 'performance', label: 'Performance' },
    { value: 'ui-ux', label: 'UI/UX' },
    { value: 'integration', label: 'Integration' },
    { value: 'other', label: 'Other' }
  ];

  constructor(
    private ticketService: TicketService,
    private stateService: StateService,
    private facilityService: FacilityService,
    private toast: ToastService,
    private router: Router
  ) {}

  ngOnInit(): void {
    this.loadStates();
  }

  loadStates(): void {
    this.stateService.getStates().subscribe({
      next: (data) => this.states = data,
      error: () => this.toast.showError('Failed to load states')
    });
  }

  onStateChange(): void {
    if (!this.selectedStateId) { this.facilities = []; this.form.facilityId = ''; return; }
    this.facilityService.getFacilities(this.selectedStateId).subscribe({
      next: (data) => this.facilities = data,
      error: () => this.toast.showError('Failed to load facilities')
    });
    this.form.facilityId = '';
  }

  submit(): void {
    if (!this.form.title.trim() || !this.form.description.trim() || !this.form.issue.trim() || !this.form.facilityId) {
      this.toast.showError('Title, description, issue, and facility are required');
      return;
    }
    this.loading = true;
    this.ticketService.createTicket(this.form).subscribe({
      next: (ticket) => {
        this.loading = false;
        this.toast.showSuccess(`Ticket #${ticket.ticketId} created`);
        this.router.navigate(['/tickets', ticket.ticketId]);
      },
      error: (err) => {
        this.loading = false;
        this.toast.showError(err?.error?.error || 'Failed to create ticket');
      }
    });
  }
}