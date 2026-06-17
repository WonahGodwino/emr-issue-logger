import { NgModule } from '@angular/core';
import { BrowserModule } from '@angular/platform-browser';
import { FormsModule, ReactiveFormsModule } from '@angular/forms';
import { HttpClientModule, HTTP_INTERCEPTORS } from '@angular/common/http';
import { CommonModule } from '@angular/common';

import { AppRoutingModule } from './app-routing.module';
import { AppComponent } from './app.component';

// Core
import { AuthInterceptor } from './core/interceptors/auth.interceptor';
import { ErrorInterceptor } from './core/interceptors/error.interceptor';
import { LoadingInterceptor } from './core/interceptors/loading.interceptor';

// Services
import { AuthService } from './core/services/auth.service';
import { TicketService } from './core/services/ticket.service';
import { UserService } from './core/services/user.service';
import { ToastService } from './core/services/toast.service';
import { LoadingService } from './core/services/loading.service';
import { StateService, FacilityService } from './core/services/state.service';

// Pages
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

// Shared Components
import { NavbarComponent } from './shared/components/navbar/navbar.component';
import { SidebarComponent } from './shared/components/sidebar/sidebar.component';
import { FooterComponent } from './shared/components/footer/footer.component';
import { StatusBadgeComponent } from './shared/components/status-badge/status-badge.component';
import { TicketCardComponent } from './shared/components/ticket-card/ticket-card.component';
import { StatisticsCardComponent } from './shared/components/statistics-card/statistics-card.component';
import { LoaderComponent } from './shared/components/loader/loader.component';
import { ToastComponent } from './shared/components/toast/toast.component';
import { ConfirmationDialogComponent } from './shared/components/confirmation-dialog/confirmation-dialog.component';
import { PaginationComponent } from './shared/components/pagination/pagination.component';
import { SearchComponent } from './shared/components/search/search.component';

// Directives & Pipes
import { AutoFocusDirective } from './shared/directives/auto-focus.directive';
import { ClickOutsideDirective } from './shared/directives/click-outside.directive';
import { ReplacePipe } from './shared/pipes/replace.pipe';
import { TruncatePipe } from './shared/pipes/truncate.pipe';

@NgModule({
  declarations: [
    AppComponent,
    LoginComponent, RegisterComponent, DashboardComponent, ProfileComponent,
    CreateTicketComponent, MyTicketsComponent, TicketDetailsComponent, EditTicketComponent,
    AdminDashboardComponent, ManageTicketsComponent, ManageUsersComponent,
    AdminStatesComponent, AdminFacilitiesComponent,
    NotFoundComponent, UnauthorizedComponent,
    NavbarComponent, SidebarComponent, FooterComponent, StatusBadgeComponent,
    TicketCardComponent, StatisticsCardComponent, LoaderComponent, ToastComponent,
    ConfirmationDialogComponent, PaginationComponent, SearchComponent,
    AutoFocusDirective, ClickOutsideDirective, ReplacePipe, TruncatePipe
  ],
  imports: [
    BrowserModule, CommonModule, AppRoutingModule, FormsModule, ReactiveFormsModule, HttpClientModule
  ],
  providers: [
    AuthService, TicketService, UserService, ToastService, LoadingService,
    StateService, FacilityService,
    { provide: HTTP_INTERCEPTORS, useClass: AuthInterceptor, multi: true },
    { provide: HTTP_INTERCEPTORS, useClass: ErrorInterceptor, multi: true },
    { provide: HTTP_INTERCEPTORS, useClass: LoadingInterceptor, multi: true }
  ],
  bootstrap: [AppComponent]
})
export class AppModule { }