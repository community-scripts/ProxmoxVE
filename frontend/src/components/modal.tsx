"use client";

type ModalProps = {
  isOpen: boolean;
  onClose: () => void;
  children: React.ReactNode;
};

const Modal: React.FC<ModalProps> = ({ isOpen, onClose, children }) => {
  if (!isOpen) return null;

  return (
    <div className="fixed inset-0 z-50 flex items-center justify-center bg-black bg-opacity-50">
      <div className="relative max-h-[90vh] w-11/12 max-w-4xl overflow-y-auto rounded-lg bg-white p-6 shadow-lg dark:bg-gray-900">
        <button
          type="button"
          onClick={onClose}
          className="absolute top-2 right-2 rounded bg-red-500 p-1 text-white"
        >
          ✖
        </button>
        {children}
      </div>
    </div>
  );
};

export default Modal;
