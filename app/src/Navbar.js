import React from 'react';

import logo from './assets/logo.png';

const Navbar = () => {
    return (
        <nav className="bg-black p-4 flex items-center justify-between fixed top-0 w-full z-10">
            <div className="flex items-center">
                <img 
                    src={logo}
                    alt="Logo" 
                    className="mr-2 w-10 h-10" 
                />
                <h1 className="text-white text-2xl font-bold">
                    <span className="text-white">LIGNE</span>
                    <span className="text-blue-500">8</span>
                </h1>
            </div>
        </nav>
    );
};

export default Navbar;
