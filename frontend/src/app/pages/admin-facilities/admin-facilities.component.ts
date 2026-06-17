import { Component, OnInit, ViewChild, ElementRef } from '@angular/core';
import { StateService, State, FacilityService, Facility, BulkUploadResult } from '../../core/services/state.service';
import { ToastService } from '../../core/services/toast.service';

@Component({
  selector: 'app-admin-facilities',
  templateUrl: './admin-facilities.component.html',
  styleUrls: ['./admin-facilities.component.css']
})
export class AdminFacilitiesComponent implements OnInit {
  @ViewChild('csvFileInput') csvFileInput!: ElementRef<HTMLInputElement>;

  states: State[] = [];
  selectedStateId = '';
  facilities: Facility[] = [];

  newFacility = { name: '', code: '', type: 'hospital', lga: '' };
  editingFacility: Facility | null = null;
  editForm = { name: '', code: '', type: '', lga: '' };
  showCreateForm = false;
  showBulkForm = false;
  bulkJson = '';
  selectedCsvFile: File | null = null;
  csvUploading = false;

  facilityTypes = [
    { value: 'hospital', label: 'Hospital' },
    { value: 'clinic', label: 'Clinic' },
    { value: 'health-center', label: 'Health Center' },
    { value: 'teaching-hospital', label: 'Teaching Hospital' },
    { value: 'specialist-center', label: 'Specialist Center' },
    { value: 'pharmacy', label: 'Pharmacy' },
    { value: 'lab', label: 'Laboratory' },
  ];

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
    this.showCreateForm = false;
    this.showBulkForm = false;
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
        this.newFacility = { name: '', code: '', type: 'hospital', lga: '' };
        this.showCreateForm = false;
        this.loadFacilities();
      },
      error: (err) => this.toast.showError(err?.error?.error || 'Failed to create facility')
    });
  }

  startEdit(facility: Facility): void {
    this.editingFacility = facility;
    this.editForm = { name: facility.name, code: facility.code, type: facility.type, lga: facility.lga || '' };
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

  bulkUploadJson(): void {
    if (!this.bulkJson.trim()) { this.toast.showError('Paste JSON array of facilities'); return; }
    let facilities: { name: string; code: string; type: string; lga?: string }[];
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

  onCsvFileSelected(event: Event): void {
    const input = event.target as HTMLInputElement;
    if (input.files && input.files.length > 0) {
      this.selectedCsvFile = input.files[0];
    }
  }

  csvUpload(): void {
    if (!this.selectedCsvFile) {
      this.toast.showError('Select a CSV file first');
      return;
    }
    this.csvUploading = true;
    this.facilityService.csvUpload(this.selectedStateId, this.selectedCsvFile).subscribe({
      next: (res: BulkUploadResult) => {
        this.csvUploading = false;
        this.toast.showSuccess(`${res.created} facilities created, ${res.failed} failed (of ${res.total ?? 0} total)`);
        if (res.failed > 0 && res.details?.failedList) {
          res.details.failedList.forEach(f => {
            this.toast.showError(`Row ${f.row}: ${f.name || 'unknown'} - ${f.error}`);
          });
        }
        this.selectedCsvFile = null;
        if (this.csvFileInput) this.csvFileInput.nativeElement.value = '';
        this.showBulkForm = false;
        this.loadFacilities();
      },
      error: (err) => {
        this.csvUploading = false;
        this.toast.showError(err?.error?.error || 'CSV upload failed');
      }
    });
  }

  downloadTemplate(): void {
    this.facilityService.downloadTemplate().subscribe({
      next: (blob: Blob) => {
        const url = window.URL.createObjectURL(blob);
        const a = document.createElement('a');
        a.href = url;
        a.download = 'facilities_template.csv';
        a.click();
        window.URL.revokeObjectURL(url);
        this.toast.showSuccess('Template downloaded');
      },
      error: () => this.toast.showError('Failed to download template')
    });
  }

  getSelectedStateName(): string {
    const state = this.states.find(s => s.stateId === this.selectedStateId);
    return state ? state.name : '';
  }
}