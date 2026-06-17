import { NgModule } from '@angular/core';
import { RouterModule, Routes } from '@angular/router';
import { AuthGuard } from './core/guards/auth.guard';
import { AdminGuard, SuperAdminGuard } from './core/guards/admin.guard';

import { LoginComponent } from './pages/login/login.component';
import { RegisterComponent } from './pages/register/register.component';
import { DashboardComponent } from './pages/dashboard/dashboard.component';
import { ProfileComponent } from './pages/profile/profile.component';
import { CreateTicketComponent } from './pages/create-ticket/create-ticket.component';
import { MyTicketsComponent } from './pages/my-tickets/my-tickets.component';
import { TicketDetailsComponent } from './pages/ticket-details/ticket-details.component';
import { EditTicketComponent } from './pages/edit-ticket/edit-ticket.component';
import { AdminDashboardComponent } from './pages/admin-dashboard/admin-dashboard.component';
import { ManageTicketsComponent } from './pages/manage-tickets/manage-tickets.component';
import { ManageUsersComponent } from './pages/manage-users/manage-users.component';
import { AdminStatesComponent } from './pages/admin-states/admin-states.component';
import { AdminFacilitiesComponent } from './pages/admin-facilities/admin-facilities.component';
import { NotFoundComponent } from './pages/not-found/not-found.component';
import { UnauthorizedComponent } from './pages/unauthorized/unauthorized.component';

const routes: Routes = [
  { path: 'login', component: LoginComponent },
  { path: 'register', component: RegisterComponent },
  { path: '', redirectTo: '/dashboard', pathMatch: 'full' },
  { path: 'dashboard', component: DashboardComponent, canActivate: [AuthGuard] },
  { path: 'profile', component: ProfileComponent, canActivate: [AuthGuard] },
  { path: 'tickets/create', component: CreateTicketComponent, canActivate: [AuthGuard] },
  { path: 'tickets', component: MyTicketsComponent, canActivate: [AuthGuard] },
  { path: 'tickets/:id', component: TicketDetailsComponent, canActivate: [AuthGuard] },
  { path: 'tickets/:id/edit', component: EditTicketComponent, canActivate: [AuthGuard] },
  { path: 'admin/dashboard', component: AdminDashboardComponent, canActivate: [AuthGuard, AdminGuard] },
  { path: 'admin/tickets', component: ManageTicketsComponent, canActivate: [AuthGuard, AdminGuard] },
  { path: 'admin/users', component: ManageUsersComponent, canActivate: [AuthGuard, AdminGuard] },
  { path: 'admin/states', component: AdminStatesComponent, canActivate: [AuthGuard, SuperAdminGuard] },
  { path: 'admin/facilities', component: AdminFacilitiesComponent, canActivate: [AuthGuard, SuperAdminGuard] },
  { path: 'unauthorized', component: UnauthorizedComponent },
  { path: '**', component: NotFoundComponent }
];

@NgModule({
  imports: [RouterModule.forRoot(routes)],
  exports: [RouterModule]
})
export class AppRoutingModule { }