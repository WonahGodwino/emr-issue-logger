import { Component, OnInit } from '@angular/core';
import { StateService, State, FacilityService, Facility } from '../../core/services/state.service';
import { ToastService } from '../../core/services/toast.service';

@Component({
  selector: 'app-admin-facilities',
  templateUrl: './admin-facilities.component.html',
  styleUrls: ['./admin-facilities.component.css']
})
export class AdminFacilitiesComponent implements OnInit {
  states: State[] = [];
  selectedStateId = '';
  facilities: Facility[] = [];

  newFacility = { name: '', code: '', type: 'hospital' };
  editingFacility: Facility | null = null;
  editForm = { name: '', code: '', type: '' };
  showCreateForm = false;
  showBulkForm = false;
  bulkJson = '';

  constructor(
    private stateService: StateService,
    private facilityService: FacilityService,
    private toast: ToastService
  ) {}

  ngOnInit(): void {
    this.stateService.getStates().subscribe({
      next: (data) => this.states = data,
      error: () => this.toast.showError('Failed to load states')
    });
  }

  onStateChange(): void {
    if (!this.selectedStateId) { this.facilities = []; return; }
    this.loadFacilities();
  }

  loadFacilities(): void {
    this.facilityService.getFacilities(this.selectedStateId).subscribe({
      next: (data) => this.facilities = data,
      error: () => this.toast.showError('Failed to load facilities')
    });
  }

  createFacility(): void {
    if (!this.newFacility.name.trim() || !this.newFacility.code.trim()) {
      this.toast.showError('Name and code are required'); return;
    }
    this.facilityService.createFacility(this.selectedStateId, this.newFacility).subscribe({
      next: () => {
        this.toast.showSuccess('Facility created');
        this.newFacility = { name: '', code: '', type: 'hospital' };
        this.showCreateForm = false;
        this.loadFacilities();
      },
      error: (err) => this.toast.showError(err?.error?.error || 'Failed to create facility')
    });
  }

  startEdit(facility: Facility): void {
    this.editingFacility = facility;
    this.editForm = { name: facility.name, code: facility.code, type: facility.type };
  }

  saveEdit(): void {
    if (!this.editingFacility || !this.selectedStateId) return;
    this.facilityService.updateFacility(this.selectedStateId, this.editingFacility.facilityId, this.editForm).subscribe({
      next: () => {
        this.toast.showSuccess('Facility updated');
        this.editingFacility = null;
        this.loadFacilities();
      },
      error: (err) => this.toast.showError(err?.error?.error || 'Failed to update')
    });
  }

  cancelEdit(): void { this.editingFacility = null; }

  deleteFacility(facility: Facility): void {
    if (!confirm(`Delete facility "${facility.name}"?`)) return;
    this.facilityService.deleteFacility(this.selectedStateId, facility.facilityId).subscribe({
      next: () => { this.toast.showSuccess('Facility deleted'); this.loadFacilities(); },
      error: () => this.toast.showError('Failed to delete facility')
    });
  }

  bulkUpload(): void {
    if (!this.bulkJson.trim()) { this.toast.showError('Paste JSON array of facilities'); return; }
    let facilities: { name: string; code: string; type: string }[];
    try { facilities = JSON.parse(this.bulkJson); }
    catch { this.toast.showError('Invalid JSON format'); return; }
    if (!Array.isArray(facilities) || facilities.length === 0) {
      this.toast.showError('Paste a valid JSON array'); return;
    }
    this.facilityService.bulkUpload(this.selectedStateId, facilities).subscribe({
      next: (res) => {
        this.toast.showSuccess(`${res.created} facilities created, ${res.failed} failed`);
        this.bulkJson = '';
        this.showBulkForm = false;
        this.loadFacilities();
      },
      error: (err) => this.toast.showError(err?.error?.error || 'Bulk upload failed')
    });
  }

  getSelectedStateName(): string {
    const state = this.states.find(s => s.stateId === this.selectedStateId);
    return state ? state.name : '';
  }
}