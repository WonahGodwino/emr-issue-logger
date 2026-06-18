import { Component, OnInit } from '@angular/core';
import { AdminService } from '../../core/services/ticket.service';
import { StateService, State } from '../../core/services/state.service';
import { ToastService } from '../../core/services/toast.service';
import { AuthService } from '../../core/services/auth.service';

interface UserRow {
  id: string; userId: string; username: string; email: string;
  fullName: string; role: string; stateIds: string[]; facilityId: string;
  createdAt: string; isActive: boolean;
}

@Component({
  selector: 'app-manage-users',
  templateUrl: './manage-users.component.html',
  styleUrls: ['./manage-users.component.css']
})
export class ManageUsersComponent implements OnInit {
  users: UserRow[] = [];
  states: State[] = [];
  loading = false;

  // State assignment modal
  selectedUser: UserRow | null = null;
  selectedStateIds: string[] = [];
  assigning = false;

  constructor(
    private adminService: AdminService,
    private stateService: StateService,
    private toast: ToastService,
    private authService: AuthService
  ) {}

  ngOnInit(): void {
    this.loadUsers();
    this.loadStates();
  }

  loadUsers(): void {
    this.loading = true;
    this.adminService.getUsers().subscribe({
      next: (data) => { this.users = data; this.loading = false; },
      error: () => { this.toast.showError('Failed to load users'); this.loading = false; }
    });
  }

  loadStates(): void {
    this.stateService.getStates().subscribe({
      next: (data) => this.states = data,
      error: () => this.toast.showError('Failed to load states')
    });
  }

  openStateAssignment(user: UserRow): void {
    this.selectedUser = user;
    this.selectedStateIds = [...(user.stateIds || [])];
  }

  closeModal(): void {
    this.selectedUser = null;
  }

  toggleState(stateId: string): void {
    const idx = this.selectedStateIds.indexOf(stateId);
    if (idx >= 0) {
      this.selectedStateIds.splice(idx, 1);
    } else {
      this.selectedStateIds.push(stateId);
    }
  }

  isStateSelected(stateId: string): boolean {
    return this.selectedStateIds.includes(stateId);
  }

  assignStates(): void {
    if (!this.selectedUser) return;
    this.assigning = true;
    this.adminService.assignStatesToAdmin(this.selectedUser.userId, this.selectedStateIds).subscribe({
      next: (res) => {
        this.assigning = false;
        this.toast.showSuccess('States assigned successfully');
        if (this.selectedUser) {
          this.selectedUser.stateIds = [...this.selectedStateIds];
        }
        this.selectedUser = null;
        this.loadUsers();
      },
      error: (err) => {
        this.assigning = false;
        this.toast.showError(err?.error?.error || 'Failed to assign states');
      }
    });
  }

  getStateName(stateId: string): string {
    const state = this.states.find(s => s.stateId === stateId);
    return state ? state.name : stateId;
  }

  getRoleBadge(role: string): string {
    switch (role) {
      case 'super_admin': return 'Super Admin';
      case 'admin': return 'Admin';
      default: return 'User';
    }
  }

  onOverlayClick(event: MouseEvent): void {
    if ((event.target as HTMLElement).classList.contains('modal-overlay')) {
      this.closeModal();
    }
  }
}