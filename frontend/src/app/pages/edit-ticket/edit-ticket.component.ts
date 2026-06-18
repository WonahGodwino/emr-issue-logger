import { Component, OnInit } from '@angular/core';
import { ActivatedRoute, Router } from '@angular/router';
import { TicketService, Ticket } from '../../core/services/ticket.service';
import { ToastService } from '../../core/services/toast.service';

@Component({
  selector: 'app-edit-ticket',
  templateUrl: './edit-ticket.component.html',
  styleUrls: ['./edit-ticket.component.css']
})
export class EditTicketComponent implements OnInit {
  ticket: Ticket | null = null;
  form = { title: '', description: '', issue: '', module: '', category: '', orderOfImpact: 1 };
  loading = true;
  saving = false;

  modules = [
    { value: 'emr', label: 'EMR' }, { value: 'pharmacy', label: 'Pharmacy' }, { value: 'lab', label: 'Lab' },
    { value: 'billing', label: 'Billing' }, { value: 'registration', label: 'Registration' },
    { value: 'reports', label: 'Reports' }, { value: 'inventory', label: 'Inventory' }, { value: 'other', label: 'Other' }
  ];

  categories = [
    { value: 'system-issue', label: 'System Issue' }, { value: 'data-integrity', label: 'Data Integrity' },
    { value: 'performance', label: 'Performance' }, { value: 'ui-ux', label: 'UI/UX' },
    { value: 'integration', label: 'Integration' }, { value: 'other', label: 'Other' }
  ];

  constructor(private route: ActivatedRoute, private ticketService: TicketService, private toast: ToastService, private router: Router) {}

  ngOnInit(): void {
    const id = this.route.snapshot.paramMap.get('id');
    if (id) this.ticketService.getTicket(id).subscribe({
      next: (t) => { this.ticket = t; this.form = { title: t.title, description: t.description, issue: t.issue, module: t.module, category: t.category, orderOfImpact: t.orderOfImpact }; this.loading = false; },
      error: () => { this.toast.showError('Ticket not found'); this.loading = false; }
    });
  }

  save(): void {
    if (!this.ticket || !this.form.title.trim()) { this.toast.showError('Title is required'); return; }
    this.saving = true;
    this.ticketService.updateTicket(this.ticket.ticketId, { ...this.form, orderOfImpact: Number(this.form.orderOfImpact) }).subscribe({
      next: () => { this.saving = false; this.toast.showSuccess('Ticket updated'); this.router.navigate(['/tickets', this.ticket?.ticketId]); },
      error: (err) => { this.saving = false; this.toast.showError(err?.error?.error || 'Failed to update'); }
    });
  }
}