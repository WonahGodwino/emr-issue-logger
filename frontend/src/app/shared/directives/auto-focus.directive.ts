import { Directive, ElementRef, Input, OnInit } from '@angular/core';

@Directive({ selector: '[appAutoFocus]' })
export class AutoFocusDirective implements OnInit {
  @Input() appAutoFocus: boolean = true;
  constructor(private el: ElementRef) {}
  ngOnInit(): void {
    if (this.appAutoFocus) {
      setTimeout(() => this.el.nativeElement.focus(), 100);
    }
  }
}
