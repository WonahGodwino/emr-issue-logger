import { Component, OnInit } from '@angular/core';
import { StateService, State } from '../../core/services/state.service';
import { ToastService } from '../../core/services/toast.service';

@Component({
  selector: 'app-admin-states',
  templateUrl: './admin-states.component.html',
  styleUrls: ['./admin-states.component.css']
})
export class AdminStatesComponent implements OnInit {
  states: State[] = [];
  newState = { name: '', code: '' };
  editingState: State | null = null;
  editForm = { name: '', code: '' };
  showCreateForm = false;

  constructor(
    private stateService: StateService,
    private toast: ToastService
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

  createState(): void {
    if (!this.newState.name.trim() || !this.newState.code.trim()) {
      this.toast.showError('Name and code are required');
      return;
    }
    this.stateService.createState(this.newState).subscribe({
      next: () => {
        this.toast.showSuccess('State created');
        this.newState = { name: '', code: '' };
        this.showCreateForm = false;
        this.loadStates();
      },
      error: (err) => this.toast.showError(err?.error?.error || 'Failed to create state')
    });
  }

  startEdit(state: State): void {
    this.editingState = state;
    this.editForm = { name: state.name, code: state.code };
  }

  saveEdit(): void {
    if (!this.editingState || !this.editForm.name.trim() || !this.editForm.code.trim()) return;
    this.stateService.updateState(this.editingState.stateId, this.editForm).subscribe({
      next: () => {
        this.toast.showSuccess('State updated');
        this.editingState = null;
        this.loadStates();
      },
      error: (err) => this.toast.showError(err?.error?.error || 'Failed to update state')
    });
  }

  cancelEdit(): void {
    this.editingState = null;
  }

  deleteState(state: State): void {
    if (!confirm(`Delete state "${state.name}" and all its facilities?`)) return;
    this.stateService.deleteState(state.stateId).subscribe({
      next: () => {
        this.toast.showSuccess('State deleted');
        this.loadStates();
      },
      error: () => this.toast.showError('Failed to delete state')
    });
  }
}